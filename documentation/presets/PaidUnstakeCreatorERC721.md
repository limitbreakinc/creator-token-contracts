# PaidUnstakeCreatorERC721.sol

**An extension of CreatorERC721 that enforces a fee to unstake/downgrade.**

## When To Use This

When you want to enforce a fee in native currency to unstake and downgrade to the original ERC721 token.  This contract can also serve as an example to inspire a custom contract enforcing a more complex set of conditions.

## Design Decisions

 * The price to unstake is immutable, and can only be set when the contract is deployed.  
   * Why: To protect holders from the centralization risk of an increased fee down the road. 

 * Unstaking fees are only accepted in native currency.  
   * Why: This covers the most common use case.

 * Precise payment is required, reverting on overpayment.
   * Why: Issuing a refund on overpayment adds expense to the unstaking transaction and has the potential to introduce re-entrancy risks.

## Usage

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/presets/PaidUnstakeCreatorERC721.sol";

contract MyCoolCollection is PaidUnstakeCreatorERC721 {
    constructor(uint256 unstakePrice_, address vanillaCollection_) PaidUnstakeCreatorERC721(unstakePrice_, vanillaCollection_, "MyCoolCollection", "MCC") {
    }

    /// @dev Add interesting new utility features here
    ...
}
```