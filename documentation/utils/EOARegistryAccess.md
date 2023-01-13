# EOARegistryAccess.sol

**A mix-in that can be applied to any contract that has a need to verify an arbitrary address is a verified EOA.**

## When To Use This

When there is a contract that needs to verify that an address has previously verified themselves as an EOA.  Take care and carefully consider whether or not to use this. Restricting operations to EOA only accounts can break Defi composability, so if Defi composability is an objective, this is not a good option.  Be advised that in the future, EOA accounts might not be a thing but this is yet to be determined.  See https://eips.ethereum.org/EIPS/eip-4337 for more information.

## Design Decisions

 * Requires a user to sign a one-time message to permanently verify they are an EOA.
   * Why: Checking msg.sender == tx.origin is a brittle check.  There has been long-running discussion to remove tx.origin support.  Extcodesize checks can also be defeated via constructors and CREATE2 with predetermined contract addresses.  By verifying a user has previously signed a message, there is no workaround that can defeat the EOA check and it should be future proof.

## Interface

The Transfer Whitelist Registry exposes the following public interface.

### **Contract Owner**

The contract owner can specify the EOA registry address using the `setEOARegistry(address eoaRegistry_)` function.

### **Read-Only**

Smart contracts, users and d'apps can determine which EOA registry is in use using the `getEOARegistry()` function.

## Usage

The following example shows how to use the mix-in to verify a token sender and receiver are both verified EOAs.  It also validates that tokens are not minted to non-EOA addresses.

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/utils/EOARegistryAccess.sol";
import "@limitbreak/creator-token-contracts/contracts/utils/TransferValidation.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error EOARegistryNotSet();
error FromAddressIsNotAnEOA();
error ToAddressIsNotAnEOA();

/// @dev By inheriting WhitelistedTransferERC721 and assigning the transfer whitelist registry
/// transfers are automatically restricted to callers that are in the whitelist.
contract MyCoolCollection is ERC721, TransferValidation, EOARegistryAccess {
    constructor(address eoaRegistry_) ERC721("MyCoolCollection", "MCC") {
        setEOARegistry(eoaRegistry_);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateBeforeTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateAfterTransfer(from, to, tokenId);
    }

    function _preValidateMint(address caller, address to, uint256 tokenId, uint256 value) internal virtual override {
        IEOARegistry eoaVerificationRegistry = getEOARegistry();
        if(address(eoaVerificationRegistry) == address(0)) {
            revert EOARegistryNotSet();
        }

        if(!eoaVerificationRegistry.isVerifiedEOA(to)) {
          revert ToAddressIsNotAnEOA();
        }
    }

    function _preValidateTransfer(address caller, address from, address to, uint256 tokenId, uint256 value) internal virtual override {
        IEOARegistry eoaVerificationRegistry = getEOARegistry();
        if(address(eoaVerificationRegistry) == address(0)) {
          revert EOARegistryNotSet();
        }

        if(!eoaVerificationRegistry.isVerifiedEOA(from)) {
          revert FromAddressIsNotAnEOA();
        }

        if(!eoaVerificationRegistry.isVerifiedEOA(to)) {
          revert ToAddressIsNotAnEOA();
        }
    }
}
```

***Note: The CreatorERC721 contract refers to an EOA Registry in the following conditions: (a) Smart contract stakers are disabled AND (b) `setEOARegistry(address eoaRegistry_)` has been used, indicating that the EOA registry is the preferred check.  It is up to the developer to decide whether or not to use the EOA registry.***