// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {UniswapV2Router} from "src/uniswap/UniswapV2Router.sol";

contract Commitment1 is Script {
    UniswapV2Router public router;

    MockERC20 public token0;
    MockERC20 public token1;

    function run() external {
        vm.startBroadcast(vm.envUint("USER_KEY"));
        address user = vm.addr(vm.envUint("USER_KEY"));

        router = UniswapV2Router(0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9);

        token0 = MockERC20(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
        token1 = MockERC20(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);

        token0.mint(user, 1 ether);
        token0.approve(address(router), 1 ether);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        // High slippage 1/100th of input
        router.swapExactTokensForTokens(1 ether, 0.01 ether, path, user);
    }
}
