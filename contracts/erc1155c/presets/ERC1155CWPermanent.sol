// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC1155CW.sol";

/**
 * @title ERC1155CWPermanent
 * @author Limit Break, Inc.
 * @notice Extension of ERC1155CW that permanently stakes the wrapped token.
 */
abstract contract ERC1155CWPermanent is ERC1155CW {

    error ERC1155CWPermanent__UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/, uint256 /*amount*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*amount*/, uint256 /*value*/) internal virtual override {
        revert ERC1155CWPermanent__UnstakeIsNotPermitted();
    }
}
