// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../CreatorERC721.sol";

error IncorrectUnstakePayment();

/**
 * @title PermanentCreatorERC721
 * @author Limit Break, Inc.
 * @notice Extension of CreatorERC721 that enforces a payment to unstake the wrapped token.
 */
abstract contract PaidUnstakeCreatorERC721 is CreatorERC721 {
    
    /// @dev The price required to unstake.  This cannot be modified after contract creation.
    uint256 immutable private unstakePrice;

    /// @dev Contstructor
    constructor(uint256 unstakePrice_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) CreatorERC721(wrappedCollectionAddress_, name_, symbol_) {
        unstakePrice = unstakePrice_;
    }

    /// @notice Returns the price, in wei, required to unstake
    function getUnstakePrice() external view returns (uint256) {
        return unstakePrice;
    }

    /// @dev Reverts if the unstaking payment is not exactly equal to the unstaking price.
    function _onUnstake(uint256 /*tokenId*/, uint256 value) internal virtual override {
        if(value != unstakePrice) {
            revert IncorrectUnstakePayment();
        }
    }
}
