// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/OwnablePermissions.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WithdrawETH
 * @author Limit Break, Inc.
 * @notice A mix-in that can be combined with any ownable contract to enable the contract owner to withdraw ETH from the contract.
 */
abstract contract WithdrawETH is OwnablePermissions {

    error WithdrawETH__AmountMustBeGreaterThanZero();
    error WithdrawETH__RecipientMustBeNonZeroAddress();
    error WithdrawETH__InsufficientBalance();
    error WithdrawETH__WithdrawalUnsuccessful();

    event Withdrawal(address indexed recipient, uint256 amount); 

    /// @notice Allows contract owner to withdraw ETH that has been paid into the contract.
    /// This allows inadvertantly lost ETH to be recovered and it also allows the contract owner
    /// To collect funds that have been properly paid into the contract over time.
    ///
    /// Throws when caller is not the contract owner.
    /// Throws when the specified amount is zero.
    /// Throws when the specified recipient is zero address.
    /// Throws when the current balance in this contract is less than the specified amount.
    /// Throws when the ETH transfer is unsuccessful.
    ///
    /// Postconditions:
    /// ---------------
    /// The specified amount of ETH has been sent to the specified recipient.
    function withdrawETH(address payable recipient, uint256 amount) external {
        _requireCallerIsContractOwner();

        if(amount == 0) {
            revert WithdrawETH__AmountMustBeGreaterThanZero();
        }

        if(recipient == address(0)) {
            revert WithdrawETH__RecipientMustBeNonZeroAddress();
        }

        if(address(this).balance < amount) {
            revert WithdrawETH__InsufficientBalance();
        }

        //slither-disable-next-line arbitrary-send        
        (bool success,) = recipient.call{value: amount}("");
        if(!success) {
            revert WithdrawETH__WithdrawalUnsuccessful();
        }

        emit Withdrawal(recipient, amount);
    }
}
