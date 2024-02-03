// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Commitment2 {
    /// @param input The `to` addresses of block transactions.
    function commitment(bytes calldata input) external view returns (uint256) {
        uint256 n = input.length / 20;
        address[] memory addresses = new address[](n);

        for (uint256 i = 0; i < n; i++) {
            addresses[i] = bytesToAddress(input[i * 20:(i + 1) * 20]);
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            address temp = addresses[i];
            for (uint256 j = 0; j < addresses.length; j++) {
                if ((j != i) && (temp == addresses[j])) {
                    return 0;
                }
            }
        }

        return 1;
    }

    function bytesToAddress(bytes calldata data) internal pure returns (address addr) {
        bytes memory b = data;
        assembly {
            addr := mload(add(b, 20))
        }
    }
}
