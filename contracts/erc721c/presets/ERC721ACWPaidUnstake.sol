// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC721ACW.sol";

/**
 * @title ERC721ACWPaidUnstake
 * @author Limit Break, Inc.
 * @notice Extension of ERC721CW that enforces a payment to unstake the wrapped token.
 */
abstract contract ERC721ACWPaidUnstake is ERC721ACW {

    error ERC721ACWPaidUnstake__IncorrectUnstakePayment();
    
    /// @dev The price required to unstake.  This cannot be modified after contract creation.
    uint256 immutable private unstakePrice;

    constructor(
        uint256 unstakePrice_, 
        address wrappedCollectionAddress_, 
        address transferValidator_, 
        string memory name_, 
        string memory symbol_) ERC721ACW(wrappedCollectionAddress_, transferValidator_, name_, symbol_) {
        unstakePrice = unstakePrice_;
    }

    /// @notice Returns the price, in wei, required to unstake
    function getUnstakePrice() external view returns (uint256) {
        return unstakePrice;
    }

    /// @dev Reverts if the unstaking payment is not exactly equal to the unstaking price.
    function _onUnstake(uint256 /*tokenId*/, uint256 value) internal virtual override {
        if(value != unstakePrice) {
            revert ERC721ACWPaidUnstake__IncorrectUnstakePayment();
        }
    }
}
