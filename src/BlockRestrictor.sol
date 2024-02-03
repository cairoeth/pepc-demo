// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract BlockRestrictor {
    error NotSuccesful();
    error BlockNumberDoesntMatch();

    function restrict(address[] memory addr, bytes[] memory data, uint256[] memory blocks) external payable {
        for (uint256 i = 0; i < blocks.length; i++) {
            if (block.number == blocks[i]) {
                for (uint256 j = 0; j < addr.length; j++) {
                    (bool success,) = addr[j].call{value: msg.value}(data[j]);
                    if (!success) revert NotSuccesful();
                }
            } else {
                revert BlockNumberDoesntMatch();
            }
        }
    }
}
