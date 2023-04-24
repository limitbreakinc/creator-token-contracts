// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/WrapperERC1155C.sol";

/**
 * @title PaidUnstakeWrapperERC1155C
 * @author Limit Break, Inc.
 * @notice Extension of ERC1155C that enforces a payment to unstake the wrapped token.
 */
abstract contract PaidUnstakeWrapperERC1155C is WrapperERC1155C {

    error PaidUnstakeWrapperERC1155C__IncorrectUnstakePayment();
    
    /// @dev The price required to unstake.  This cannot be modified after contract creation.
    uint256 immutable private unstakeUnitPrice;

    constructor(
        uint256 unstakeUnitPrice_, 
        address wrappedCollectionAddress_, 
        address transferValidator_, 
        string memory uri_) WrapperERC1155C(wrappedCollectionAddress_, transferValidator_, uri_) {
        unstakeUnitPrice = unstakeUnitPrice_;
    }

    /// @notice Returns the price, in wei, required to unstake per one item.
    function getUnstakeUnitPrice() external view returns (uint256) {
        return unstakeUnitPrice;
    }

    /// @dev Reverts if the unstaking payment is not exactly equal to the unstaking price.
    function _onUnstake(uint256 /*tokenId*/, uint256 amount, uint256 value) internal virtual override {
        if(value != amount * unstakeUnitPrice) {
            revert PaidUnstakeWrapperERC1155C__IncorrectUnstakePayment();
        }
    }
}
