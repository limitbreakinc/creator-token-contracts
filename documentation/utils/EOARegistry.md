# EOARegistry.sol

**A deployable contract where users can sign a message to prove they are an EOA.  A global community-use EOA registry will be deployed and made available as there is no real need for users to prove they are an EOA in more than one contract.**

## When To Use This

Any contract that needs to determine if an arbitrary address is a known, proven EOA can query the EOA registry.  For example, in a contract that only allows EOA to EOA transfers.

## Design Decisions

 * Signer must submit their own signature.  No submissions on the signer's behalf.
   * Why: This ensures that the user is consciously opting in and verifying they are an EOA.

## Interface

The EOA Registry exposes the following public interface.

* `isVerifiedEOA(address account)` - (view-only) returns true if the specified account has verified a signature on this registry, false otherwise.
* `verifySignature(bytes calldata signature)` - allows a user to verify an ECDSA signature to definitively prove they are an EOA account.
* `verifySignatureVRS(uint8 v, bytes32 r, bytes32 s)` - allows a user to verify an ECDSA signature to definitively prove they are an EOA account.  This version is passed the v, r, s components of the signature, and is slightly more gas efficient than calculating the v, r, s components on-chain.

## Usage

Users sign the string `"EOA"` with the account they want to verify as an EOA.  Applications then call on of the `verifySignature` functions, passing in the signature.

For Ethers.js, see the following documentation.

https://docs.ethers.org/v5/api/signer/#Signer-signMessage

For web3.js refer to this documentation.

https://web3js.readthedocs.io/en/v1.8.1/web3-eth-personal.html?highlight=sign#sign

If using a different library, see data signing documentation from your preferred library.

***Note: The CreatorERC721 contract refers to an EOA Registry in the following conditions: (a) Smart contract stakers are disabled AND (b) `setEOARegistry(address eoaRegistry_)` has been used, indicating that the EOA registry is the preferred check.  It is up to the developer to decide whether or not to use the EOA registry.***