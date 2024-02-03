// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract Commitment2 is Script {
    MockERC20 public token0;

    function run() external {
        vm.startBroadcast(vm.envUint("KEY"));

        token0 = MockERC20(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);
        
        token0.approve(address(0xbeef), 1 ether);
        token0.approve(address(0xbeef), 1 ether);
    }
}
