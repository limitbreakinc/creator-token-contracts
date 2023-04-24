// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/extensions/WrapperERC721C.sol";

/**
 * @title PermanentWrapperERC721C
 * @author Limit Break, Inc.
 * @notice Extension of ERC721C that permanently stakes the wrapped token.
 */
abstract contract PermanentWrapperERC721C is WrapperERC721C {

    error PermanentWrapperERC721C__UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        revert PermanentWrapperERC721C__UnstakeIsNotPermitted();
    }
}
