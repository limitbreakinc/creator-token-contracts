# Creator Token Contracts

**A backwards compatible library of NFT contract standards and mix-ins that power programmable royalty use cases and expand possible NFT use cases by introducing creator tokens.** 

## Installation with Hardhat/Truffle

```console
$ npm install @limitbreak/creator-token-contracts
```

## Installation with Foundry

With an existing foundry project:

```bash
forge install limitbreakinc/creator-token-contracts
```

Update your `remappings.txt` file to resolve imports.

## Usage

Once installed, you can use the contracts in the library by importing them.

***Note: This contract library contains Initializable variations of several contracts an mix-ins.  The initialization functions are meant for use ONLY with EIP-1167 Minimal Proxies (Clones).  The use of the term "Initializable" is not meant to imply that these contracts are suitable for use in Upgradeable Proxy contracts.  This contract library should NOT be used in any upgradeable contract, as they do not provide storage-safety should additional contract variables be added in future versions.  Limit Break has no intentions to make this library suitable for upgradeability and developers are solely responsible for adapting the code should they use it in an upgradeable contract.*** 

## Cloning The Source Code

```bash
git clone https://github.com/limitbreakinc/creator-token-contracts.git
```

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Code Coverage

```bash
./scripts/test/generate-coverage-report.sh
```

### Documentation

```bash
forge doc -s
> Serving on: http://localhost:3000
```

Open a browser to http://localhost:3000 to view docs.

Clone the repository

## Overview

* **Extended NFT Standards**
   * [AdventureERC721](./contracts/adventures/AdventureERC721.sol) - Limit Break's adventure token standard that provides flexible hard and soft staking mechanics to enable on-chain adventures and quests.
   * [ERC721C](./contracts/erc721c/ERC721C.sol) - Extends OpenZeppelin's ERC721 implementation, adding creator-definable transfer security profiles that are the foundation for enforceable, programmable royalties.
   * [ERC1155C](./contracts/erc1155c/ERC1155C.sol) - Extends OpenZeppelin's ERC1155 implementation, adding creator-definable transfer security profiles that are the foundation for enforceable, programmable royalties.
   * [AdventureERC721C](./contracts/erc721c/AdventureERC721C.sol) - Extends Limit Break's AdventureERC721 implementation, adding creator-definable transfer security profiles that are the foundation for enforceable, programmable royalties.
   * [ERC721AC](./contracts/erc721c/ERC721AC.sol) - Extends Azuki's ERC721-A implementation, adding creator-definable transfer security profiles that are the foundation for enforceable, programmable royalties.

* **Wrapper Standards**
   * [ERC721CW](./contracts/erc721c/extensions/ERC721CW.sol) - Extends ERC721C and introduces opt-in staking/unstaking as a form of token wrapping/unwrapping. This is backwards compatible and enables any vanilla ERC721 token to be upgraded to an ERC721C with enhanced utility at the discretion of token holders who can choose whether to stake into the new state or not.
   * [ERC1155CW](./contracts/erc1155c/extensions/ERC1155CW.sol) - Extends ERC1155C and introduces opt-in staking/unstaking as a form of token wrapping/unwrapping. This is backwards compatible and enables any vanilla ERC1155 token to be upgraded to an ERC1155C with enhanced utility at the discretion of token holders who can choose whether to stake into the new state or not.
   * [AdventureERC721CW](./contracts/erc721c/extensions/AdventureERC721CW.sol) - Extends AdventureERC721C and introduces opt-in staking/unstaking as a form of token wrapping/unwrapping. This is backwards compatible and enables any vanilla ERC721 token to be upgraded to an AdventureERC721C with enhanced utility at the discretion of token holders who can choose whether to stake into the new state or not.

* **Interfaces** - for ease of integration, the following interfaces have been defined for 3rd party consumption
    * [ICreatorToken](./contracts/interfaces/ICreatorToken.sol) - Base interface for all Creator Token Implementations.
    * [ICreatorTokenWrapperERC721](./contracts/interfaces/ICreatorToken.sol) - Base interface for all Wrapper Creator Token ERC721 Implementations.
    * [ICreatorTokenWrapperERC1155](./contracts/interfaces/ICreatorToken.sol) - Base interface for all Wrapper Creator Token ERC721 Implementations.
    * [ICreatorTokenTransferValidator](./contracts/interfaces/ICreatorToken.sol) - Base interface to provide access to all security policy management functionality in the Creator Token Transfer Validator.

* **Infrastructure**
   * [EOARegistry](./contracts/utils/EOARegistry.sol) - A deployable contract where users can sign a message to prove they are an EOA. A global community-use EOA registry will be deployed and made available as there is no real need for users to prove they are an EOA in more than one contract.
   * [CreatorTokenTransferValidator](./contracts/utils/CreatorTokenTransferValidator.sol) - Extends EOA registry and enables creators to set transfer security levels, create and manage whitelists/contract receiver allow lists, and apply their creator-defined policies to one or more creator token collections they own.  All the different implementations of creator token standards point to this registry for application of transfer security policies.

* **Programmable Royalty Sample Mix-Ins for ERC-721**
    * [ImmutableMinterRoyalties](./contracts/programmable-royalties/ImmutableMinterRoyalties.sol) - A mix-in that grants minters permanent royalty rights to the NFT token ID they minted.  Royalty fee cannot be changed.
    * [MutableMinterRoyalties](./contracts/programmable-royalties/MutableMinterRoyalties.sol) - A mix-in that grants minters permanent royalty rights to the NFT token ID they minted.  Royalty fee for each token ID can be changed by the minter of that token id.
    * [MinterCreatorSharedRoyalties](./contracts/programmable-royalties/MinterCreatorSharedRoyalties.sol) - A mix-in that grants minters a permanent share of royalty rights to the NFT token ID they minted.  Royalty fees for each token ID are shared between the NFT creator and the minter according to a ratio of shares defined at contract creation.  A payment splitter is created for each token ID to split funds between the minter and creator.

* **Marketplaces**
    * [OrderFulfillmentOnchainRoyalties](./contracts/marketplaces/OrderFulfillmentOnchainRoyalties.sol) - A mix-in contract that provides on-chain royalties management during NFT sales. It can be used as-is or as an example for third-party marketplace contracts to read on-chain royalties and payout proceeds from NFT sales to the royalty recipient, seller, and dispense the NFTs to the buyer.

 * **Miscellaneous**
   * [EOARegistryAccess](./contracts/utils/EOARegistryAccess.sol) - A mix-in that can be applied to any contract that has a need to verify an arbitrary address is a verified EOA.
   * [TransferValidation](./contracts/utils/TransferValidation.sol) - A mix-in that can be used to decompose _beforeTransferToken and _afterTransferToken into granular pre and post mint/burn/transfer validation hooks.  These hooks provide finer grained controls over the lifecycle of an ERC721 token.

* **Presets**
   * [ERC721CWPermanent](./contracts/erc721c/presets/ERC721CWPermanent.sol) - does not allow unstaking to retrieve the wrapped token.
   * [ERC721CWPaidUnstake](./contracts/erc721c/presets/ERC721CWPaidUnstake.sol) - allows unstaking with payment of an unstaking fee.
   * [ERC721CWTimeLockedUnstake](./contracts/erc721c/presets/ERC721CWTimeLocked.sol) -  allows unstaking any time after a time lock expires.
   * [ERC1155CWPermanent](./contracts/erc1155c/presets/ERC1155CWPermanent.sol) - does not allow unstaking to retrieve the wrapped token.
   * [ERC1155CWPaidUnstake](./contracts/erc1155c/presets/ERC1155CWPaidUnstake.sol) - allows unstaking with payment of an unstaking fee.

* **Examples**
   * [ERC721CWithImmutableMinterRoyalties](./contracts/examples/erc721c/ERC721CWithImmutableMinterRoyalties.sol)
   * [ERC721CWithMutableMinterRoyalties](./contracts/examples/erc721c/ERC721CWithMutableMinterRoyalties.sol)
   * [ERC721CWithMinterCreatorSharedRoyalties](./contracts/examples/erc721c/ERC721CWithMinterCreatorSharedRoyalties.sol)
   * [ERC721ACWithImmutableMinterRoyalties](./contracts/examples/erc721ac/ERC721ACWithImmutableMinterRoyalties.sol)
   * [ERC721ACWithMutableMinterRoyalties](./contracts/examples/erc721ac/ERC721ACWithMutableMinterRoyalties.sol)
   * [ERC721ACWithMinterCreatorSharedRoyalties](./contracts/examples/erc721ac/ERC721ACWithMinterCreatorSharedRoyalties.sol)
   * [AdventureERC721CWithImmutableMinterRoyalties](./contracts/examples/adventure-erc721c/AdventureERC721CWithImmutableMinterRoyalties.sol)
   * [AdventureERC721CWithMutableMinterRoyalties](./contracts/examples/adventure-erc721c/AdventureERC721CWithMutableMinterRoyalties.sol)
   * [AdventureERC721CWithMinterCreatorSharedRoyalties](./contracts/examples/adventure-erc721c/AdventureERC721CWithMinterCreatorSharedRoyalties.sol)

## How To Guides

### How To Build, Deploy, and Setup a Creator Token

1. Choose a standard (ERC721-C, ERC721-AC, AdventureERC721-C, or ERC1155-C)
2. Inherit the selected standard, for example:

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/ERC721C.sol";

contract MyCollection is ERC721C {
    
    constructor() ERC721C("MyCollection", "MC") {}
    
    ...
}
```

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/ERC721AC.sol";

contract MyCollection is ERC721AC {
    
    constructor() ERC721AC("MyCollection", "MC") {}
    
    ...
}
```

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/AdventureERC721C.sol";

contract MyCollection is AdventureERC721C {
    
    constructor() AdventureERC721C(10, "MyCollection", "MC") {}
    
    ...
}
```

3. Add your token URI logic, minting logic, and other features specific to your collection.  For example:

```solidity

contract MyCollection is ERC721C {
    
    ...

    function ownerMint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function publicMint() external {
        ...
    }

    // TODO: Other collection-specific contract features here
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollection/metadata/";
    }
}
```

4. Use preferred smart contract development framework (eg Truffle, Hardhat, Foundry) to deploy and verify contract.  It is assumed developers already know how to do this, but instructions for [Foundry can be found here.](https://book.getfoundry.sh/forge/deploying)

5. It is strongly encouraged to transfer ownership of your contracts to a multi-sig, such as Gnosis Safe and to require multiple keys to sign off on each transaction.

6. To set up a collection to use the default security settings, call the `setToDefaultSecurityPolicy` function on your NFT contract using Etherscan or Gnosis Safe UIs.  Alternately, to set up a collection to use custom security settings, call the `setToCustomSecurityPolicy` function on your NFT contract with the custom validator address, security level, operator whitelist ID, and permitted contract receiver allowlist ID.

### How To Use The Creator Token Transfer Validator To Manage Security Settings For Collections

The `CreatorTokenTransferValidator` is a smart contract used for managing and applying security policies to token transfers. It provides a comprehensive set of configurable security policies to help control token transfers, while also allowing external on-chain whitelisting of operators and permitted contract receivers.  The magic of creator tokens is applied in this infrastructure contract.  Limit Break has deployed this contract on Ethereum Mainnet, Polygon Mainnet, as well as Sepolia and Mumbai testnets at the following address: `0x0000721C310194CcfC01E523fc93C9cCcFa2A0Ac`.

The `CreatorTokenTransferValidator` has the following features:

- Create, manage, and apply security policies for token transfers
- Manage operator whitelists and permitted contract receiver allowlists
- Apply different security policies to different collections
- Control token transfers based on the caller and receiver constraints
- Use events to track changes in security policies and allowlists

Interact with the deployed contract using the provided functions to create, manage, and apply security policies.  A multi-sig such as Gnosis safe is strongly encouraged, and the Gnosis Safe transaction builder can be used to securely manage collections using the following functions.

#### Security Policy Management
- `applyCollectionTransferPolicy(address caller, address from, address to):` Validates a token transfer based on the security policy applied to the collection.
- `setTransferSecurityLevelOfCollection(address collection, TransferSecurityLevels level):` Sets the security level of a collection.
- `getCollectionSecurityPolicy(address collection):` Retrieves the security policy for a given collection.

#### Operator Whitelist Management
- `createOperatorWhitelist(string calldata name):` Creates a new operator whitelist.
- `reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner):` Reassigns the ownership of an operator whitelist.
- `renounceOwnershipOfOperatorWhitelist(uint120 id):` Renounces ownership of an operator whitelist.
- `setOperatorWhitelistOfCollection(address collection, uint120 id):` Sets the operator whitelist for a collection.
- `addOperatorToWhitelist(uint120 id, address operator):` Adds an operator to a whitelist.
- `removeOperatorFromWhitelist(uint120 id, address operator):` Removes an operator from a whitelist.
- `isOperatorWhitelisted(uint120 id, address operator):` Checks if an operator is whitelisted.
- `getWhitelistedOperators(uint120 id):` Retrieves the whitelisted operators for a given id.

#### Permitted Contract Receiver Allowlist Management
- `createPermittedContractReceiverAllowlist(string calldata name):` Creates a new permitted contract receiver allowlist.
- `reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner):` Reassigns the ownership of a permitted contract receiver allowlist.
- `renounceOwnershipOfPermittedContractReceiverAllowlist(uint120 id):` Renounces ownership of a permitted contract receiver allowlist.
- `setPermittedContractReceiverAllowlistOfCollection(address collection, uint120 id):` Sets the permitted contract receiver allowlist for a collection.
- `addPermittedContractReceiverToAllowlist(uint120 id, address receiver):` Adds a permitted contract receiver to an allowlist.
- `removePermittedContractReceiverFromAllowlist(uint120 id, address receiver):` Removes a permitted contract receiver from an allowlist.
- `isContractReceiverPermitted(uint120 id, address receiver):` Checks if a contract receiver is permitted.
- `getPermittedContractReceivers(uint120 id):` Retrieves the permitted contract receivers for a given id.

#### Events
- `CreatedAllowlist`
- `ReassignedAllowlistOwnership`
- `SetTransferSecurityLevel`
- `SetAllowlist`
- `AddedToAllowlist`
- `RemovedFromAllowlist`

For more information, please refer to the contract code comments and the provided function descriptions.

The `CreatorTokenTransferValidator` contract defines 7 transfer security levels, each represented by a unique `TransferSecurityPolicy`. Each policy consists of a combination of caller and receiver constraints to define varying levels of security for token transfers.

#### **Transfer Security Levels Description**

0. **TransferSecurityLevels.Zero:**

   - Caller Constraints: None
   - Receiver Constraints: None
   - This is the most relaxed level of security, allowing any caller to initiate a token transfer to any receiver without any restrictions.

1. **TransferSecurityLevels.One:**

   - Caller Constraints: OperatorWhitelistEnableOTC (Over-the-counter)
   - Receiver Constraints: None
   - In this level, the caller must be whitelisted as an operator or the owner of the token. There are no constraints on the receiver.

2. **TransferSecurityLevels.Two:**

   - Caller Constraints: OperatorWhitelistDisableOTC
   - Receiver Constraints: None
   - The caller must be whitelisted as an operator, and OTC transfers initiated by the token owner are not allowed. There are no constraints on the receiver.

3. **TransferSecurityLevels.Three:**

   - Caller Constraints: OperatorWhitelistEnableOTC
   - Receiver Constraints: NoCode
   - The caller must be whitelisted as an operator or the owner of the token. The receiver must not have deployed code, which means they cannot be a smart contract.  Specific contract receivers can optionally be designated in a permitted contract receivers allowlist.

4. **TransferSecurityLevels.Four:**

   - Caller Constraints: OperatorWhitelistEnableOTC
   - Receiver Constraints: EOA (Externally Owned Account)
   - The caller must be whitelisted as an operator or the owner of the token. The receiver must be an EOA, which means they cannot be a smart contract and must have performed a one-time signature verification in the `CreatorTokenTransferValidator`.  Specific contract receivers can optionally be designated in a permitted contract receivers allowlist.

5. **TransferSecurityLevels.Five:**

   - Caller Constraints: OperatorWhitelistDisableOTC
   - Receiver Constraints: NoCode
   - The caller must be whitelisted as an operator, and OTC transfers initiated by the token owner are not allowed. The receiver must not have deployed code, which means they cannot be a smart contract.  Specific contract receivers can optionally be designated in a permitted contract receivers allowlist.

6. **TransferSecurityLevels.Six:**

   - Caller Constraints: OperatorWhitelistDisableOTC
   - Receiver Constraints: EOA
   - The caller must be whitelisted as an operator, and OTC transfers initiated by the token owner are not allowed. The receiver must be an EOA, which means they cannot be a smart contract and must have performed a one-time signature verification in the `CreatorTokenTransferValidator`.  Specific contract receivers can optionally be designated in a permitted contract receivers allowlist.

These predefined transfer security levels can be applied to collections to implement varying levels of transfer security based on the collection's requirements.

### How To Build, Deploy, and Setup a Wrapper Creator Token (Upgrade a Prior Collection Using Staking)

1. Choose a wrapper standard (ERC721-CW, AdventureERC721-CW, or ERC1155-CW)
2. Inherit the selected standard, for example:

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/extensions/ERC721CW.sol";

contract MyCollection is ERC721CW {
    
    constructor(address wrappedCollectionAddress_) ERC721CW(wrappedCollectionAddress_, "MyCollection", "MC") {}
    
    ...
}
```

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/erc721c/AdventureERC721CW.sol";

contract MyCollection is AdventureERC721CW {
    
    constructor(address wrappedCollectionAddress_) AdventureERC721C(wrappedCollectionAddress_, 10, "MyCollection", "MC") {}
    
    ...
}
```

3. Add your token URI logic and other features specific to your collection.  For example:

```solidity

contract MyCollection is ERC721CW {

    ...

    // TODO: Other collection-specific contract features here
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollection/metadata/";
    }
}
```

4. Use preferred smart contract development framework (eg Truffle, Hardhat, Foundry) to deploy and verify contract.  It is assumed developers already know how to do this, but instructions for [Foundry can be found here.](https://book.getfoundry.sh/forge/deploying)

5. It is strongly encouraged to transfer ownership of your contracts to a multi-sig, such as Gnosis Safe and to require multiple keys to sign off on each transaction.

6. To set up a collection to use the default security settings, call the `setToDefaultSecurityPolicy` function on your NFT contract using Etherscan or Gnosis Safe UIs.  Alternately, to set up a collection to use custom security settings, call the `setToCustomSecurityPolicy` function on your NFT contract with the custom validator address, security level, operator whitelist ID, and permitted contract receiver allowlist ID.

7. By default, any address can stake.  But to apply staking constraints to prevent contracts from staking to wrap token, the contract owner can use the `setStakerConstraints(StakerConstraints stakerConstraints_)` function with `StakerConstraints.None`, `StakerConstraints.CallerIsTxOrigin`, or `StakerConstraints.EOA`.

## How To Implement Programmable Royalties Using A Mix-In

It is simple to implement programmable royalties as a mix-in and combine with creator tokens such as ERC721-C.

1. Choose from one of the examples (ImmutableMinterRoyalties, MutableMinterRoyalties, or MinterCreatorSharedRoyalties) or write your own mix-in that implements the IERC2981 interface for royalties.

2. Choose a standard (ERC721-C, ERC721-AC, AdventureERC721-C, ERC721-CW, or AdventureERC721-CW)

2. Write a contract that inherits the selected standard and mix-in.  For example:

```solidity
import "@limitbreak/creator-token-contracts/contracts/erc721c/AdventureERC721C.sol";
import "@limitbreak/creator-token-contracts/contracts/programmable-royalties/MutableMinterRoyalties.sol";

contract AdventureERC721CWithMutableMinterRoyalties is AdventureERC721C, MutableMinterRoyalties {

    constructor(
        uint96 defaultRoyaltyFeeNumerator_,
        uint256 maxSimultaneousQuests_,
        string memory name_,
        string memory symbol_) 
        AdventureERC721C(maxSimultaneousQuests_, name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    ...
}
```

3. Override the supportsInterface function to handle multiple inheritance.

```solidity

contract AdventureERC721CWithMutableMinterRoyalties is AdventureERC721C, MutableMinterRoyalties {

    ...

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, MutableMinterRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ...
}
```

4. Implement public/external mint, safeMint, burn functions as needed for your collection.

```solidity

contract AdventureERC721CWithMutableMinterRoyalties is AdventureERC721C, MutableMinterRoyalties {

    ...

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    ...
}
```

5. Override the _mint and _burn functions.  Call _onMinted or _onBurned respectively and then call the base implementation.  

```solidity

contract AdventureERC721CWithMutableMinterRoyalties is AdventureERC721C, MutableMinterRoyalties {

    ...

    function _mint(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }

    ...
}
```

6.  Complete code for this example [can be found here](./contracts/examples/adventure-erc721c/AdventureERC721CWithMutableMinterRoyalties.sol).  There are numerous other examples to look at in the [contracts/examples](./contracts/examples/) folder.

### How To Use Order Fulfillment Onchain Royalties Mixin For Existing Marketplaces

This mix-in is designed to be integrated with an existing NFT marketplace's smart contract to ensure that onchain royalties defined using EIP-2981 are honored. It provides a simple and secure way to fulfill single-item orders, transferring payments and NFTs between buyers, sellers, and royalty recipients.

### Features
- Supports native currency (ETH) and ERC-20 payments
- Handles ERC-721 and ERC-1155 NFT transfers
- Calculates and enforces onchain royalties according to EIP-2981
- Can be used for single item sale, batch sales, bundled sales, or collection sweep orders
- Requires minimal changes to an existing marketplace's tech stack, only requiring a modified marketplace smart contract that uses this mixin

### Usage

1. Import the mixin and its data types into your existing marketplace smart contract:
```solidity
import "@limitbreak/creator-token-contracts/contracts/marketplaces/OrderFulfillmentOnchainRoyalties.sol";
import "@limitbreak/creator-token-contracts/contracts/marketplaces/OrderFulfillmentOnchainRoyaltiesDataTypes.sol";
```

2. Inherit the `OrderFulfillmentOnchainRoyalties` contract and call the `fulfillSingleItemOrder` function after order validation and platform fee deductions:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@limitbreak/creator-token-contracts/contracts/marketplaces/OrderFulfillmentOnchainRoyalties.sol";
import "@limitbreak/creator-token-contracts/contracts/marketplaces/OrderFulfillmentOnchainRoyaltiesDataTypes.sol";

contract MyMarketplace is OrderFulfillmentOnchainRoyalties {
    // Your existing marketplace code here

    function executeOrder(Execution memory execution) external {
        // Perform all order validations and other required logic here

        OrderDetails memory orderDetails = _translateOrderDetails(execution);
        fulfillSingleItemOrder(orderDetails, 2300); // 2300 gas limit for native currency payments
    }

    function _translateOrderDetails(Execution memory execution) private pure returns (OrderDetails memory) {
        Order memory sellOrder = execution.sell.order;
        Order memory buyOrder = execution.buy.order;
        
        uint256 platformFeesDeducted = 0;
        for (uint256 i = 0; i < sellOrder.fees.length; i++) {
            platformFeesDeducted += (sellOrder.price * sellOrder.fees[i].rate) / FEE_DENOMINATOR;
        }

        return OrderDetails({
            protocol: sellOrder.collection == address(0) ? CollectionProtocols.ERC721 : CollectionProtocols.ERC1155,
            seller: sellOrder.trader,
            buyer: buyOrder.trader,
            paymentMethod: sellOrder.paymentToken,
            tokenAddress: sellOrder.collection,
            tokenId: sellOrder.tokenId,
            amount: sellOrder.amount,
            priceBeforePlatformFees: sellOrder.price,
            platformFeesDeducted: platformFeesDeducted,
            maxRoyaltyFeeNumerator: getMaxRoyaltyFeeNumerator() // Implement this function to get the maximum royalty fee numerator allowed by your marketplace
        });
    }
    
    // Your other marketplace functions here
}
```

The `_translateOrderDetails` function is responsible for converting the native `Execution` data structure into the `OrderDetails` structure used by the mixin. 

Don't forget to test and adjust the code as needed to ensure proper functioning and security of your platform.

3. Update the order validation logic and other necessary parts of your marketplace contract to support the new mixin.

**Note:** The marketplace contract is responsible for performing all order validations.  The marketplace contract is also responsible for collecting platform fees, if applicable, but should not collect royalty fees as the mix-in will handle that.  However, the mix-in will take care of computing and distributing royalties defined in NFT contracts via the EIP-2981 interface and distributing remaining proceeds to the seller.  The mix-in will then dispense the NFT to the buyer.

### Gas Limit Considerations
The `fulfillSingleItemOrder` function accepts a gas limit for pushing native currency/ETH payments. The default value should be 2300 gas unless there are changes in the gas cost of the CALL EVM opcode in the future.

### Disclaimer
It is crucial to thoroughly test the integration of this mixin with your specific marketplace implementation to ensure the security and proper functioning of your platform. This mixin provides a general-purpose solution but may require adjustments or customizations depending on your use case.

## Limit Break Curated Whitelist

**This is the list of exchanges that Limit Break has determined pay creator royalties consistently.  The whitelist is maintained solely by Limit Break and is controlled by a company Multi-Sig wallet.**

| Marketplace | Network | Address |
|-|-|-|
| OpenSea | ALL | 0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC |
| X2Y2 | ETH | 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3 |
| Rarible | ETH | 0xcd4EC7b66fbc029C116BA9Ffb3e59351c20B5B06 |
| Rarible | ETH | 0x9757F2d2b135150BBeb65308D4a91804107cd8D6 |
| Foundation | ETH | 0xcDA72070E455bb31C7690a170224Ce43623d0B6f |
| Nifty Gateway | ETH | 0xE052113bd7D7700d623414a0a4585BCaE754E9d5 |
| Nifty Gateway | ETH | 0xE86aD94Ef70d59e17A03Aa40338688094Db03769 |
| SuperRare | ETH | 0x65B49f7AEE40347f5A90b714be4eF086f3fe5E2C |
| SuperRare | ETH | 0x8c9F364bf7a56Ed058fc63Ef81c6Cf09c833e656 |
| Zora | ETH | 0x76744367ae5a056381868f716bdf0b13ae1aeaa3 |
| Zora | ETH | 0xe468ce99444174bd3bbbed09209577d25d1ad673 |
| Zora | ETH | 0x6170b3c3a54c3d8c854934cbc314ed479b2b29a3 |
| Zora | ETH | 0x5f7072e1fa7c01dfac7cf54289621afaad2184d0 |
| Zora | ETH | 0xe5bfab544eca83849c53464f85b7164375bdaac1 |
| Zora | ETH | 0x9458e29713b98bf452ee9b2c099289f533a5f377 |
| Zora | ETH | 0x34aa9cbb80dc0b3d82d04900c02fb81468dafcab |
| GigaMart v1.0 | ETH | 0xcA833F943a0C7D3C4021B0b161a2686f9ebf6b02 |
| GigaMart Aggregator v1.0 | ETH | 0x4C9712Cd94376C537464cAa4d87bce198d59936c |
| GigaMart v1.1 | ETH | 0xEC5cE37242b17D9C54Ade5DD71C29d2183FAEfD1 |
| GigaMart Aggregator v1.1 | ETH | 0x6e1B3e68EE6fc68939ABE89829831DeAa1843DC2 |

To be considered for the whitelist or to propose a new exchange, teams can reach out to blockchain@limitbreak.com.

## Security and License

This project is made available by Limit Break in an effort to provide an open-source functional library of smart contract components to be used by other parties as precedent for individual user’s creation and deployment of smart contracts in the Etherium ecosystem (the “Limit Break Contracts”). Limit Break is committed to following, and has sought to apply, commercially reasonable best practices as it pertains to safety and security in making the Limit Break Contracts publicly available for use as precedent. Nevertheless, smart contracts are a new and emerging technology and carry a high level of technical risk and uncertainty. Despite Limit Break’s commitment and efforts to foster safety and security in their adoption, using the precedent contracts made available by this project is not a substitute for a security audit conducted by the end user. Please report any actual or suspected security vulnerabilities to our team at [security@limitbreak.com](security@limitbreak.com).

The Limit Break Contracts are made available under the [MIT License](LICENSE), which disclaims all warranties in relation to the project and which limits the liability of those that contribute and maintain the project, including Limit Break. As set out further in Limit Break’s [Terms of Service](https://limitbreak.com/tos.html), as may be amended and revised from time to time, you acknowledge that you are solely responsible for any use of the Limit Break Contracts and you assume all risks associated with any such use. For the avoidance of doubt, such assumption of risk by the user also implies all risks associated with the legality or related implications tied to the use of smart contracts in any given jurisdiction, whether now known or yet to be determined.

Limit Break's offering of the code in Creator Token Contracts has no bearing on Limit Break's own implementations of programmable royalties.