// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../CreatorERC721.sol";

error UnstakeIsNotPermitted();

/**
 * @title PermanentCreatorERC721
 * @author Limit Break, Inc.
 * @notice Extension of CreatorERC721 that permanently stakes the wrapped token.
 */
abstract contract PermanentCreatorERC721 is CreatorERC721 {

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        revert UnstakeIsNotPermitted();
    }
}
