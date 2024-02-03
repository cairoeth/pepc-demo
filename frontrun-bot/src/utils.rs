use ethers::prelude::*;
use eyre::Result;
use std::sync::Arc;

/// Return a Provider for the given URL
pub fn get_http_provider() -> Result<Provider<Http>> {
    let url = "http://127.0.0.1:8545";
    Provider::<Http>::try_from(url).map_err(|_| eyre::eyre!("Invalid RPC URL"))
}

/// Construct the searcher wallet
pub fn get_searcher_wallet() -> Result<LocalWallet> {
    let private_key = "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
    private_key
        .parse::<LocalWallet>()
        .map_err(|e| eyre::eyre!("Failed to parse private key: {:?}", e))
}

/// Creates a client from a provider
pub fn create_http_client(
    p: Provider<Http>,
    chain_id: u64,
) -> Result<Arc<SignerMiddleware<Provider<Http>, LocalWallet>>> {
    let wallet = get_searcher_wallet()?;
    let client = SignerMiddleware::new(p, wallet.with_chain_id(chain_id));
    Ok(Arc::new(client))
}

pub fn eaddress_to_raddress(addr: &ethers::types::Address) -> revm::primitives::Address {
    revm::primitives::Address::from(addr.0)
}

pub fn raddress_to_eaddress(addr: &revm::primitives::Address) -> ethers::types::Address {
    ethers::types::Address::from(addr.0 .0)
}
