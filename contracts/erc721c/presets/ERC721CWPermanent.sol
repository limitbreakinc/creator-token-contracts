// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC721CW.sol";

/**
 * @title ERC721CWPermanent
 * @author Limit Break, Inc.
 * @notice Extension of ERC721CW that permanently stakes the wrapped token.
 */
abstract contract ERC721CWPermanent is ERC721CW {

    error ERC721CWPermanent__UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        revert ERC721CWPermanent__UnstakeIsNotPermitted();
    }
}
