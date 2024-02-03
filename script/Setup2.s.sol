// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {Singleton} from "src/Singleton.sol";
import {Commitment2} from "src/Commitment2.sol";

contract Setup2 is Script {
    Singleton public manager;
    Commitment2 public commitment;

    function run() external {
        vm.startBroadcast(vm.envUint("KEY"));

        manager = Singleton(0x0165878A594ca255338adfa4d48449f69242Eb8F);

        commitment = new Commitment2();

        manager.makeCommitment(bytes32(""), address(commitment), Commitment2.commitment.selector);
    }
}
