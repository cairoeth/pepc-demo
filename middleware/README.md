## PEPC Middleware example for Anvil

Here you can find the patch for Anvil that adds PEPC middleware functionality. To apply the patch, following these steps:

1. Clone Foundry (which contains Anvil):

```shell
git clone https://github.com/foundry-rs/foundry && cd foundry
```
2. Copy the patch from this directory to the root of the foundry repository and apply it:

```shell
git apply pepc.patch
```

3. To run modified Anvil:

```shell
cd crates/anvil && cargo run -- --block-time 12
```