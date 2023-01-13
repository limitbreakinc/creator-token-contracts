// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../EOAOnlyCreatorERC721.sol";

/**
 * @title EOAOnlyPermanentCreatorERC721
 * @author Limit Break, Inc.
 * @notice Extension of EOAOnlyCreatorERC721 that permanently stakes the wrapped token.
 */
abstract contract EOAOnlyPermanentCreatorERC721 is EOAOnlyCreatorERC721 {

    error UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        revert UnstakeIsNotPermitted();
    }
}
