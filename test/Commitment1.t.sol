// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {UniswapV2Factory} from "src/uniswap/UniswapV2Factory.sol";
import {UniswapV2Router} from "src/uniswap/UniswapV2Router.sol";
import {UniswapV2Pair} from "src/uniswap/UniswapV2Pair.sol";
import {UniswapV2Library} from "src/uniswap/UniswapV2Library.sol";
import {BlockRestrictor} from "src/BlockRestrictor.sol";

import {Singleton} from "src/Singleton.sol";
import {Commitment1} from "src/Commitment1.sol";
import {Commitment2} from "src/Commitment2.sol";

import "emily/lib/types.sol";

contract TestCommitment1 is Test {
    using CommitmentsLib for Commitment[];

    UniswapV2Factory public factory;
    UniswapV2Router public router;
    BlockRestrictor public blockRestrictor;

    Singleton public manager;
    Commitment1 public commitment1;
    Commitment2 public commitment2;

    MockERC20 public token0;
    MockERC20 public token1;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        token0 = new MockERC20("UniswapToken0", "UT0", 18);
        token1 = new MockERC20("UniswapToken1", "UT1", 18);

        token0.mint(address(this), 10 ether);
        token1.mint(address(this), 10 ether);

        manager = new Singleton(1000000, 0);
        blockRestrictor = new BlockRestrictor();
        commitment1 = new Commitment1(address(router));
        commitment2 = new Commitment2();
    }

    function testMain() public {
        token0.approve(address(router), 1 ether);
        token1.approve(address(router), 1 ether);

        router.addLiquidity(address(token0), address(token1), 1 ether, 1 ether, 1 ether, 1 ether, address(this));

        address pairAddress = factory.pairs(address(token0), address(token1));
        assertEq(pairAddress, 0x751605723249E6d187E5a062b8e3590A61Da1aA3);

        manager.makeCommitment(bytes32(""), address(commitment1), Commitment1.commitment.selector);

        assertTrue(manager.screen(address(this), bytes32(""), hex""));

        vm.warp(block.timestamp + 1);

        assertTrue(manager.screen(address(this), bytes32(""), hex""));

        assertTrue(
            manager.screen(address(this), bytes32(""), abi.encodePacked(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707))
        );

        address[] memory addresses = new address[](2);
        addresses[0] = address(factory.pairs(address(token0), address(token1)));
        addresses[1] = address(router);

        bytes memory data = encodeAddressArray(addresses);

        assertFalse(manager.screen(address(this), bytes32(""), data));

        // Switch orders.
        addresses[1] = address(factory.pairs(address(token0), address(token1)));
        addresses[0] = address(router);

        data = encodeAddressArray(addresses);

        assertTrue(manager.screen(address(this), bytes32(""), data));
    }

    function testGetHash() public view {
        console.logBytes32(keccak256(type(UniswapV2Pair).creationCode));
    }

    function encodeAddressArray(address[] memory addresses) internal pure returns (bytes memory data) {
        for (uint256 i = 0; i < addresses.length; i++) {
            data = abi.encodePacked(data, addresses[i]);
        }
    }
}
