## 🥤 PEPC Middleware Demo

Demo with two commitment exampels, `Commitment1` and `Commitment2`. The former establishes a restriction that if a block contains a transaciton to the Uniswap router, it must be placed first in the block (i.e. transaction index must be 0). The latter establishes a commitment that each transaciton in a block must be pointing to different `to` addresses.

For `Commitment1`, this project also contains a front-running bot built with [Artemis](https://github.com/paradigmxyz/artemis) that will try to front-run a user's Uniswap transaction. This is used as an example together with the middleware to showcase how MEV can be mitigated.

## Front-running bot

### Build

```shell
$ cargo b
```

### Run

```shell
$ cargo run <WS> <PRIVATE_KEY> <CONTRACT_ADDRESS> <UNISWAP_ADDRESS>
```

## Smart contracts

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