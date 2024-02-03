// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Pair} from "src/uniswap/interfaces/IUniswapV2Pair.sol";

contract Sandwich {
    using SafeERC20 for IERC20;

    // Authorized
    address internal immutable user;

    // Contructor sets the only user
    receive() external payable {}

    constructor() {
        user = msg.sender;
    }

    /// @notice Receive ERC20 token profits.
    /// @param token address of the token you're recovering
    function recoverERC20(IERC20 token) external {
        require(msg.sender == user);
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    /// @param token address of the token you're swapping
    /// @param pair univ2 pair you're sandwiching on
    /// @param amountIn amount you're giving via swap
    /// @param amountOut amount you're receiving via swap
    /// @param tokenOutNo is the token you're giving token0 or token1? (On univ2 pair)
    function go(address token, address pair, uint256 amountIn, uint256 amountOut, uint8 tokenOutNo) external {
        IERC20(token).transfer(pair, amountIn);

        IUniswapV2Pair(pair).swap(
            tokenOutNo == 0 ? amountOut : 0, tokenOutNo == 1 ? amountOut : 0, address(this), new bytes(0)
        );
    }
}
