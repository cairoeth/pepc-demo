// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {Singleton} from "src/Singleton.sol";
import {Commitment2} from "src/Commitment2.sol";

contract TestCommitment2 is Test {
    Singleton public manager;
    Commitment2 public commitment;

    function setUp() public {
        manager = new Singleton(1000000, 0);
        commitment = new Commitment2();
    }

    function testMain() public {
        manager.makeCommitment(bytes32(""), address(commitment), Commitment2.commitment.selector);

        assertTrue(manager.screen(address(this), bytes32(""), hex""));

        vm.warp(block.timestamp + 1);

        assertTrue(manager.screen(address(this), bytes32(""), hex""));

        address[] memory addresses = new address[](2);
        addresses[0] = address(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);
        addresses[1] = address(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);

        bytes memory data = encodeAddressArray(addresses);

        console.logBytes(
            abi.encodeWithSelector(
                manager.screen.selector, address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266), bytes32(""), data
            )
        );

        assertFalse(manager.screen(address(this), bytes32(""), data));

        addresses[1] = address(0xbeef);
        data = encodeAddressArray(addresses);

        assertTrue(manager.screen(address(this), bytes32(""), data));
    }

    function encodeAddressArray(address[] memory addresses) internal pure returns (bytes memory data) {
        for (uint256 i = 0; i < addresses.length; i++) {
            data = abi.encodePacked(data, addresses[i]);
        }
    }
}
