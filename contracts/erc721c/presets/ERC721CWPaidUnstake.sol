// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../extensions/ERC721CW.sol";

/**
 * @title ERC721CWPaidUnstake
 * @author Limit Break, Inc.
 * @notice Extension of ERC721CW that enforces a payment to unstake the wrapped token.
 */
abstract contract ERC721CWPaidUnstake is ERC721CW {

    error ERC721CWPaidUnstake__IncorrectUnstakePayment();
    
    /// @dev The price required to unstake.  This cannot be modified after contract creation.
    uint256 immutable private unstakePrice;

    constructor(
        uint256 unstakePrice_, 
        address wrappedCollectionAddress_, 
        string memory name_, 
        string memory symbol_) ERC721CW(wrappedCollectionAddress_) ERC721OpenZeppelin(name_, symbol_) {
        unstakePrice = unstakePrice_;
    }

    /// @notice Returns the price, in wei, required to unstake
    function getUnstakePrice() external view returns (uint256) {
        return unstakePrice;
    }

    /// @dev Reverts if the unstaking payment is not exactly equal to the unstaking price.
    function _onUnstake(uint256 /*tokenId*/, uint256 value) internal virtual override {
        if(value != unstakePrice) {
            revert ERC721CWPaidUnstake__IncorrectUnstakePayment();
        }
    }
}
