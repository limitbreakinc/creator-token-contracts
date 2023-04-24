// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/WrapperERC1155C.sol";

/**
 * @title PermanentWrapperER11551C
 * @author Limit Break, Inc.
 * @notice Extension of ERC1155C that permanently stakes the wrapped token.
 */
abstract contract PermanentWrapperERC1155C is WrapperERC1155C {

    error PermanentWrapperERC1155C__UnstakeIsNotPermitted();

    /// @notice Permanent Creator Tokens Are Never Unstakeable
    function canUnstake(uint256 /*tokenId*/, uint256 /*amount*/) public virtual view override returns (bool) {
        return false;
    }

    /// @dev Reverts on any attempt to unstake.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*amount*/, uint256 /*value*/) internal virtual override {
        revert PermanentWrapperERC1155C__UnstakeIsNotPermitted();
    }
}
