// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {CommitmentManager} from "emily/CommitmentManager.sol";
import {Screener} from "emily/Screener.sol";

contract Singleton is CommitmentManager, Screener {
    constructor(uint256 accountCommitmentsGasLimit, uint256 finalization)
        CommitmentManager(accountCommitmentsGasLimit, finalization)
    {
        _setCommitmentManager(address(this));
    }
}
