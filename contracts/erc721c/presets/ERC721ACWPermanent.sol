// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC721ACW.sol";

/**
 * @title ERC721ACWPermanent
 * @author Limit Break, Inc.
 * @notice Extension of ERC721ACW that permanently stakes the wrapped token.
 */
abstract contract ERC721ACWPermanent is ERC721ACW {

    error ERC721ACWPermanent__UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        revert ERC721ACWPermanent__UnstakeIsNotPermitted();
    }
}
