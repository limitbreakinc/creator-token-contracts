// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC1155CW.sol";

/**
 * @title ERC1155CWPaidUnstake
 * @author Limit Break, Inc.
 * @notice Extension of ERC1155CW that enforces a payment to unstake the wrapped token.
 */
abstract contract ERC1155CWPaidUnstake is ERC1155CW {

    error ERC1155CWPaidUnstake__IncorrectUnstakePayment();
    
    /// @dev The price required to unstake.  This cannot be modified after contract creation.
    uint256 immutable private unstakeUnitPrice;

    constructor(
        uint256 unstakeUnitPrice_, 
        address wrappedCollectionAddress_, 
        string memory uri_) ERC1155CW(wrappedCollectionAddress_) ERC1155OpenZeppelin(uri_) {
        unstakeUnitPrice = unstakeUnitPrice_;
    }

    /// @notice Returns the price, in wei, required to unstake per one item.
    function getUnstakeUnitPrice() external view returns (uint256) {
        return unstakeUnitPrice;
    }

    /// @dev Reverts if the unstaking payment is not exactly equal to the unstaking price.
    function _onUnstake(uint256 /*tokenId*/, uint256 amount, uint256 value) internal virtual override {
        if(value != amount * unstakeUnitPrice) {
            revert ERC1155CWPaidUnstake__IncorrectUnstakePayment();
        }
    }
}
