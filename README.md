## 🥤 PEPC Middleware Demo

Demo with two commitment examples, `Commitment1` and `Commitment2`. The former establishes a restriction that if a block contains a transaction to the Uniswap router, it must be placed first in the block (i.e. top-of-block, transaction index must be 0). The latter establishes a commitment that the transactions in a block have non-overlapping targets (i.e., different `to` addresses).

For `Commitment1`, this project also contains a front-running bot built with [Artemis](https://github.com/paradigmxyz/artemis) that will try to front-run a user's Uniswap transaction. This is used as an example together with the middleware to showcase how MEV can be mitigated.

## Middleware

As an example of a PEPC middleware, this project modifies Anvil to check that produced blocks fulfill the commitments of a proposer. To do so, it passes the transaction data of the block as a `bytes` parameter to the Screener contract, which in turn calls the `CommitmentManager` for the given proposer address and target. If the proposer made a commitment for the `target`, the `CommitmentManager` will pass the `bytes` parameter to the commitment contract (for example, `Commitment1`) which returns `1` if the commitment is satisfied, and `0` if not. If the commitment is not satisfied, the Anvil middleware will split the transactions into different blocks to satisfy the commitment.

If the setup (`CommitmentManager`, etc.) is not deployed, Anvil will continue to create blocks every 12 seconds. Similarly, blocks will be produced if the mempool is empty.

You can find the Anvil modifications in the patch file [here](https://github.com/cairoeth/pepc-demo/blob/master/middleware/pepc.patch).

### Run

1. Clone Foundry (which contains Anvil):

```shell
git clone https://github.com/foundry-rs/foundry && cd foundry
```
2. Copy the patch file to the root of the `foundry` repository and apply it:

```shell
git apply pepc.patch
```

3. Run the modified Anvil:

```shell
cd crates/anvil && cargo run -- --block-time 12
```

## Front-running bot

For a complete demo, this project includes a front-running bot that will monitor the Anvil mempool targetting Uniswap swaps. The bot will calculate the profitability of a sandwich attack before front-runnning the user by passing a higher fee. Anvil orders transactions based on the fee, placing the bot's transaction before the user's swap.

To run the bot, make sure to run Anvil and prepare the environment with the `Setup1` script.

### Run

```shell
$ cargo run <WS> <PRIVATE_KEY> <CONTRACT_ADDRESS> <UNISWAP_ADDRESS>
```

## Smart contracts

The smart contracts of the commitment samples and the bot's bot contract are written in Solidity with Foundry. The `Singleton` contract combines both the `Screener` and `CommitmentManager` for simplicity.

#### Commitment1: top-of-block

This commitment establishes a restriction that if a block contains a transaction to the Uniswap router, it must be placed first in the block (i.e. transaction index must be 0). It defines a `commitment` function that takes a `bytes` parameter, which is an `abi.encodePacked` list of `to` addresses from the block transactions. First, it decodes the `bytes` parameter into a list of addresses, which are then iterated to check if one is the Uniswap router address. If it is, the function will check that the index in the list is 0, meaning that the transaction is the first in the block. If this is true, the commitment is satisfied, so the function will return `1`. Otherwise, it will return `0`.

You can find the commitment contract [here](https://github.com/cairoeth/pepc-demo/blob/master/src/Commitment1.sol).

#### Commitment2: non-overlapping transaction targets

This commitment establishes a restriction that all transactions in a block must be pointing to different `to` addresses. It defines a `commitment` function that takes a `bytes` parameter, which is an `abi.encodePacked` list of `to` addresses from the block transactions. First, it decodes the `bytes` parameter into a list of addresses, which are then iterated to check that all the addresses in the list are unique. If this is true, the commitment is satisfied, so the function will return `1`. Otherwise, it will return `0`.

You can find the commitment contract [here](https://github.com/cairoeth/pepc-demo/blob/master/src/Commitment2.sol).

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Demo steps

### Vanilla Anvil + Commitment1 example

1. Run Anvil: `anvil --block-time 12`
2. Deploy Setup1: `forge script script/Setup1.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
3. Run bot: `cargo run ws://127.0.0.1:8545 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`
4. Run Swap demo: `forge script script/Commitment1.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
5. Check Anvil made a block with 4 transactions, first one being front-run from bot.

### PEPC middleware for Anvil + Commitment1 example

1. Run modified Anvil: `cargo run -- --block-time 12`
2. Deploy Setup1: `forge script script/Setup1.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
3. Run bot: `cargo run ws://127.0.0.1:8545 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`
4. Run Swap demo: `forge script script/Commitment1.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
5. Check how Anvil made a block with only 3 transactions, skipping the front-run. All of the transactions are from the user. The next block contains the bot's transaction.

### PEPC middleware for Anvil + Commitment2 example

1. Run steps from [previous example](#pepc-middleware-for-anvil--commitment1-example)
1. Deploy Setup2: `forge script script/Setup2.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
2. Run demo: `forge script script/Commitment2.s.sol --rpc-url http://127.0.0.1:8545 --broadcast -vvvv`
3. Check how the two transactions got separated into different blocks to fulfill the commitment.
