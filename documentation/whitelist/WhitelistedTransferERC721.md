# WhitelistedTransferERC721.sol

**Extends TransferValidation and Open Zeppelin's ERC721 contracts to include a reference to an external transfer whitelist registry.  Adds the option for the developer to limit transfers such that they can only be executed by approved, whitelisted callers.**

## When To Use This

When you want control over the marketplaces that are permitted to execute trades on the token.  Alternately, use the whitelist with specialty operator contracts to enforce specific control flows during token transfers.  

## Design Decisions

 * Whitelist registry can be changed by the contract owner after initialization.  
   * Why: In case the whitelist registry contract owner keys/multi-sig are somehow compromised, this allows the contract owner to point to a fresh registry.

 * Whitelist registry can be changed back to the zero address.
   * Why: In case the contract owner wants to remove whitelist transfer restrictions later, the registry address can be reset to point to zero again, re-enabling unrestricted transfers.

 * Wallet to wallet transfers are not permitted.
   * Why: It is more secure for users if a malicious phishing site cannot directly transfer or gain approval to transfer tokens.  Marketplaces have a workaround for this where you can sell to a specific buyer at a low price if a user just wants to transfer tokens between their own wallets.

## Interface

The Transfer Whitelist Registry exposes the following public interface.

### **Contract Owner**

The contract owner can specify the whitelist registry address using the `setWhitelistRegistry(address whitelistRegistry_)` function.

### **Read-Only**

Smart contracts, users and d'apps can determine which whitelist registry is in use using the `getTransferWhitelist()` function.

## Development, Deployment, and Setup Process

![](../images/dev-process-transfer-whitelist.png)

## Usage

For security purposes, the ownership of the transfer whitelist registry contract should not be assigned to the same address as the contract that specifies which whitelist registry to use.  It is strongly recommended that the owner of the Whitelisted Transfer ERC721 token be assigned to a multi-sig.

Anyone can inherit WhitelistedTransferERC721 to get a basic ERC721 token with whitelisted transfer restrictions.  Additional functionality may be added on top of this base contract.  New projects may use this contract directly if you want to mint directly into the whitelist restricted state without requiring opt-in staking.

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