# PermanentCreatorERC721.sol

**An extension of CreatorERC721 that does not permit unstaking/downgrading.**

## When To Use This

When you want to enforce one-way upgrading of an NFT that can never be downgraded.

## Design Decisions

 * This makes staking a creator token permanent where the original wrapped NFT can never be unwrapped.
   * Why: There are many projects where it would not make sense to ever recover the original wrapped token.  Many games may have mechanics that work well with this.

## Usage

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/presets/PermanentCreatorERC721.sol";

contract MyCoolCollection is PermanentCreatorERC721 {
    constructor(address vanillaCollection_) PermanentCreatorERC721(vanillaCollection_, "MyCoolCollection", "MCC") {
    }

    /// @dev Add interesting new utility features here
    ...
}
```