# TimeLockedUnstakeCreatorERC721.sol

**An extension of CreatorERC721 that enforces a waiting period between staking and unstaking.**

## When To Use This

When you want to enforce a minimum time that a token must be staked before the holder can unstake to downgrade to the original ERC721 token.  This contract can also serve as an example to inspire a custom contract enforcing a more complex set of conditions.

## Design Decisions

 * The time lock duration is immutable, and can only be set when the contract is deployed.  
   * Why: To protect holders from the centralization risk of an increased time lock down the road. 

 * The time lock duration is specified in seconds.
   * Why: block.timestamp returns a timestamp in seconds, so it is the most natural unit of time and requires no conversion to easily compare the stake timestamp with the timestamp during an unstake operation.


## Usage

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/presets/TimeLockedUnstakeCreatorERC721.sol";

contract MyCoolCollection is TimeLockedUnstakeCreatorERC721 {
    constructor(uint256 timelockSeconds_, address vanillaCollection_) TimeLockedUnstakeCreatorERC721(timelockSeconds_, vanillaCollection_, "MyCoolCollection", "MCC") {
    }

    /// @dev Add interesting new utility features here
    ...
}
```