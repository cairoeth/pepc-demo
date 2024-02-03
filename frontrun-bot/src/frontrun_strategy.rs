use std::sync::Arc;

use artemis_core::executors::mempool_executor::{GasBidInfo, SubmitTxToMempool};
use artemis_core::types::Strategy;
use async_trait::async_trait;
use ethers::abi::Token;
use ethers::prelude::transaction::eip2718::TypedTransaction;
use ethers::prelude::{Middleware, TransactionRequest};
use ethers::types::Transaction;
use revm::primitives::{hex, Address};

use crate::{abi, numeric, uniswap, utils};

pub struct FrontRunStrategy<M: Middleware> {
    pub bot_address: Address,
    pub uniswap_address: Address,
    pub sender_address: Address,
    pub provider: Arc<M>,
}

impl<M> FrontRunStrategy<M>
where
    M: Middleware + 'static,
{
    async fn process_tx(&mut self, tx: Transaction) -> anyhow::Result<Option<SubmitTxToMempool>> {
        // Decode the transaction data
        let decoded = if let Ok(d) = abi::decode_uniswap_router_calldata(&tx.input) {
            d
        } else {
            tracing::debug!("Failed to decode transaction data, skipping...");
            return Ok(None);
        };

        let user_min_recv = decoded.amount_out_min;
        let user_amount_in = decoded.amount_in;

        tracing::info!(
            "[DETECTED] Potential sandwichable transaction: {:#?}",
            decoded
        );

        // Calculate sandwichability
        let token_a = decoded.path[0];
        let token_b = decoded.path[1];

        // Get the pair to sandwich
        let pair_to_sandwich =
            if let Ok(p) = uniswap::calculate_uniswap_v2_pair_address(&token_a, &token_b) {
                p
            } else {
                tracing::debug!(
                    "Failed to get uniswap v2 pair address for tokens [{:?}, {:?}], skipping...",
                    token_a,
                    token_b
                );
                return Ok(None);
            };
        tracing::info!("Found pair to swandwich: {:?}", pair_to_sandwich);

        // Get the token reserves
        let (mut token_a_reserves, mut token_b_reserves) =
            if let Ok(r) = uniswap::get_uniswap_v2_reserves(&pair_to_sandwich).await {
                r
            } else {
                tracing::debug!(
                    "Failed to get uniswap v2 reserves for pair {:?}, skipping...",
                    pair_to_sandwich
                );
                return Ok(None);
            };

        // Swap the amounts if tokens are not in order
        if token_a > token_b {
            (token_a_reserves, token_b_reserves) = (token_b_reserves, token_a_reserves);
        }

        // Caclulate the optimal swap amount
        tracing::info!("Calculating optimal swap amount...");
        let optimal_in = numeric::calculate_sandwich_optimal_in(
            &user_amount_in,
            &user_min_recv,
            &token_a_reserves,
            &token_b_reserves,
        );
        tracing::info!(
            "[CALC] Optimal swap amount: {} token",
            ethers::utils::format_units(optimal_in, "ether")
                .unwrap_or_else(|_| optimal_in.to_string())
        );

        // Nothing to sandwich
        if optimal_in <= ethers::types::U256::zero() {
            tracing::warn!(
                "[LOSS] Nothing to sandwich! Optimal Weth In: {}, Skipping...",
                optimal_in
            );
            return Ok(None);
        }

        // Calculate the sandwich context
        // Contains full parameters and pool states for sandwich construction
        let sandwich_context = if let Ok(sc) = numeric::calculate_sandwich_context(
            &optimal_in,
            &user_amount_in,
            &user_min_recv,
            &token_a_reserves,
            &token_b_reserves,
        ) {
            sc
        } else {
            tracing::warn!("[ABORT] Failed to calculate sandwich context, skipping...");
            return Ok(None);
        };

        tracing::info!("Found Sandwich Context {:#?}", sandwich_context);

        let chain_id = self.provider.get_chainid().await?.as_u64();

        let token_out_no = if token_a > token_b {
            ethers::types::U256::from(1)
        } else {
            ethers::types::U256::from(0)
        };

        Ok(Some(SubmitTxToMempool {
            tx: TypedTransaction::Legacy(
                TransactionRequest::new()
                    .from(utils::raddress_to_eaddress(&self.sender_address))
                    .to(utils::raddress_to_eaddress(&self.bot_address))
                    .data(
                        calls_to_calldata(
                            token_a,
                            pair_to_sandwich,
                            optimal_in,
                            sandwich_context.frontrun_state.variable,
                            token_out_no,
                        )
                        .to_vec(),
                    )
                    .chain_id(chain_id)
                    .gas(ethers::types::U256::from(250000)),
            ),
            gas_bid_info: Some(GasBidInfo {
                total_profit: sandwich_context.revenue,
                bid_percentage: 10,
            }),
        }))
    }
}

#[async_trait]
impl<M> Strategy<Transaction, SubmitTxToMempool> for FrontRunStrategy<M>
where
    M: Middleware + 'static,
{
    async fn sync_state(&mut self) -> anyhow::Result<()> {
        Ok(())
    }

    async fn process_event(&mut self, event: Transaction) -> Vec<SubmitTxToMempool> {
        if utils::eaddress_to_raddress(&event.to.unwrap()) != self.uniswap_address {
            return vec![];
        }

        tracing::info!("received tx: {:?}", event);

        let result = self.process_tx(event).await;

        match result {
            Ok(Some(tx)) => vec![tx],
            Ok(None) => vec![],
            Err(err) => {
                tracing::error!("Error processing tx: {:?}", err);
                vec![]
            }
        }
    }
}

fn calls_to_calldata(
    token_a: ethers::types::H160,
    pair_to_sandwich: ethers::types::H160,
    optimal_in: ethers::types::U256,
    amount_out: ethers::types::U256,
    token_out_no: ethers::types::U256,
) -> revm::primitives::Bytes {
    // cast sig "go(address,address,uint256,uint256,uint8)"
    const GO_SIG: [u8; 4] = hex!("96563fec");

    GO_SIG
        .iter()
        .copied()
        .chain(
            ethers::abi::encode(&[
                Token::Address(token_a),
                Token::Address(pair_to_sandwich),
                Token::Uint(optimal_in),
                Token::Uint(amount_out),
                Token::Uint(token_out_no),
            ])
            .drain(..),
        )
        .collect::<Vec<_>>()
        .into()
}
