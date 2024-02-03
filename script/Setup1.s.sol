// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {UniswapV2Factory} from "src/uniswap/UniswapV2Factory.sol";
import {UniswapV2Router} from "src/uniswap/UniswapV2Router.sol";
import {BlockRestrictor} from "src/BlockRestrictor.sol";

import {Singleton} from "src/Singleton.sol";
import {Commitment1} from "src/Commitment1.sol";

import {Sandwich} from "src/Sandwich.sol";

contract Setup1 is Script {
    UniswapV2Factory public factory;
    UniswapV2Router public router;
    BlockRestrictor public blockRestrictor;

    Singleton public manager;
    Commitment1 public commitment;

    MockERC20 public token0;
    MockERC20 public token1;

    Sandwich public bot;

    function run() external {
        vm.startBroadcast(vm.envUint("KEY"));

        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        token0 = new MockERC20("UniswapToken0", "UT0", 18);
        token1 = new MockERC20("UniswapToken1", "UT1", 18);

        manager = new Singleton(1000000, 1);
        blockRestrictor = new BlockRestrictor();
        bot = new Sandwich();

        commitment = new Commitment1(address(router));

        manager.makeCommitment(bytes32(""), address(commitment), Commitment1.commitment.selector);

        token0.mint(vm.addr(vm.envUint("KEY")), 10 ether);
        token1.mint(vm.addr(vm.envUint("KEY")), 10 ether);

        token0.approve(address(router), 10 ether);
        token1.approve(address(router), 10 ether);

        router.addLiquidity(
            address(token0), address(token1), 10 ether, 10 ether, 10 ether, 10 ether, vm.addr(vm.envUint("KEY"))
        );

        token0.mint(address(bot), 100 ether);
        token1.mint(address(bot), 100 ether);
    }
}
