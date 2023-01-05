# TransferWhitelistRegistry.sol

**A deployable whitelist of exchanges permitted to execute transfers.  Developers may optionally deploy and curate their own whitelist or they may point to a community-curated whitelist.**

## When To Use This

When you have an ERC-721 token that implements whitelisted transfer capabilities and you want control over the marketplaces that are permitted to execute trades on the token.  Another powerful use case is to whitelist a specialty operator contract as a way to enforce minimum floor prices, rising floor prices, token-gated transfers, holder royalties, etc.  

## Design Decisions

 * Allows all transfers if no exchanges are in the whitelist.  
   * Why: Requires that a minimum of one exchange must always be available for trading, otherwise tokens can be freely traded or transferred anywhere.

 * Whitelist is not enumerable on-chain.
   * Why: It is less gas efficient to store an array in addition to a mapping, and the whitelist can be indexed off-chain by tracking the *ExchangeAddedToWhitelist* and *ExchangeRemovedFromWhitelist* event logs.

## Interface

The Transfer Whitelist Registry exposes the following public interface.

### **Contract Owner**

The contract owner controls the whitelist using the `whitelistExchange(address account)` and `unwhitelistExchange(address account)` functions.

### **Read-Only**

Smart contracts and d'apps can read the state of the whitelist using the following read-only functions:

* `getWhitelistedExchangeCount()` - returns the number of exchanges that are currently in the whitelist.
* ` isWhitelistedExchange(address account)` - returns true if the specified account is in the whitelist, false otherwise.
* `isTransferWhitelisted(address caller)` - returns true if the caller is permitted to execute a transfer, false otherwise.

## Current Limit Break Whitelist

The current Limit Break Whitelist can be found [here](../LimitBreakCuratedWhitelist.md).

## Usage

For security purposes and to limit centralization risks it is strongly recommended that the owner of transfer whitelist registry be assigned to a multi-sig or another multi-party governance structure.  For added security, the ownership of the transfer whitelist registry contract should not be assigned to the same address as the contract that specifies which whitelist registry to use.

Any contract inheriting from WhitelistedTransferERC721 or CreatorERC721 can use the transfer whitelist registry with minimal development effort.

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/whitelist/WhitelistedTransferERC721.sol";

/// @dev By inheriting WhitelistedTransferERC721 and assigning the transfer whitelist registry
/// transfers are automatically restricted to callers that are in the whitelist.
contract MyCoolCollection is WhitelistedTransferERC721 {
    constructor(address whitelistRegistry_) ERC721("MyCoolCollection", "MCC") {
        setWhitelistRegistry(whitelistRegistry_);
    }
}
```

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/CreatorERC721.sol";

/// @dev By inheriting CreatorERC721 and assigning the transfer whitelist registry
/// transfers are automatically restricted to callers that are in the whitelist.
contract MyCoolCollection is CreatorERC721 {
    constructor(address whitelistRegistry_, address vanillaCollection_) CreatorERC721(vanillaCollection_, "MyCoolCollection", "MCC") {
        setWhitelistRegistry(whitelistRegistry_);
    }
}
```