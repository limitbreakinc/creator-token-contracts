# Creator Token Contracts

**A backwards compatible library of building blocks that allows creators to build opt-in NFTs that expand possible NFT use cases by introducing transfer whitelists.** 

## Overview

* **ERC721 Extensions** - extensions for OpenZeppelin's standard ERC721 token implementation
   * ***[TransferValidation.sol](./documentation/utils/TransferValidation.md)*** - A mix-in that can be used to decompose _beforeTransferToken and _afterTransferToken into granular pre and post mint/burn/transfer validation hooks.  These hooks provide finer grained controls over the lifecycle of an ERC721 token.
   * ***[WhitelistedTransferERC721.sol](./documentation/whitelist/WhitelistedTransferERC721.md)*** - Extends TransferValidation and ERC721 contracts to include a reference to an external transfer whitelist registry.  Adds the option for the developer to limit transfers such that they can only be executed by approved, whitelisted callers.
   * ***[CreatorERC721.sol](./documentation/CreatorERC721.md)*** - Extends WhitelistedTransferERC721 and introduces opt-in staking/unstaking as a form of token wrapping/unwrapping.  This is backwards compatible and enables any vanilla ERC721 token to be upgraded to an ERC721 with enhanced utility and whitelisted transfers at the discretion of token holders who can choose whether to stake into the new state or not.
   * **Presets** - the following may be used as is, or to serve as examples and inspire additional variations
     * ***[PermanentCreatorERC721.sol](./documentation/presets/PermanentCreatorERC721.md)*** - does not allow unstaking to retrieve the wrapped token.
     * ***[TimeLockedUnstakeCreatorERC721.sol](./documentation/presets/TimeLockedUnstakeCreatorERC721.md)*** - allows unstaking any time after a time lock expires.
     * ***[PaidUnstakeCreatorERC721.sol](./documentation/presets/PaidUnstakeCreatorERC721.md)*** - allows unstaking with payment of an unstaking fee.
 * **Registries**
   * ***[TransferWhitelistRegistry.sol](./documentation/whitelist/TransferWhitelistRegistry.md)*** - A deployable whitelist of exchanges permitted to execute transfers.  Developers may optionally deploy and curate their own whitelist or they may point to a community-curated whitelist.
   * ***[EOARegistry.sol](./documentation/utils/EOARegistry.md)*** - A deployable contract where users can sign a message to prove they are an EOA.  A global community-use EOA registry will be deployed and made available as there is no real need for users to prove they are an EOA in more than one contract.
 * **Miscellaneous**
   * ***[EOARegistryAccess.sol](./documentation/utils/EOARegistryAccess.md)*** - A mix-in that can be applied to any contract that has a need to verify an arbitrary address is a verified EOA.

### Installation

```console
$ npm install @limitbreak/creator-token-contracts
```

### Usage

Once installed, you can use the contracts in the library by importing them.

#### Adding Transfer Whitelist To A New Collection

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/whitelist/WhitelistedTransferERC721.sol";

/// @dev By inheriting WhitelistedTransferERC721 and assigning the transfer whitelist registry
/// transfers are automatically restricted to callers that are in the whitelist.
contract MyCollection is WhitelistedTransferERC721 {
    
    constructor() ERC721("MyCollection", "MC") {}
    
    function ownerMint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
    
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollection/metadata/";
    }
}
```

#### Upgrading an Old Collection Using Staking

```solidity
pragma solidity ^0.8.4;

import "@limitbreak/creator-token-contracts/contracts/presets/PermanentCreatorERC721.sol";
import "@limitbreak/creator-token-contracts/contracts/presets/PaidUnstakeCreatorERC721.sol";
import "@limitbreak/creator-token-contracts/contracts/presets/TimeLockedUnstakeCreatorERC721.sol";

/// @dev By inheriting PermanentCreatorERC721 and assigning the wrapped collection
/// address, a permanent token upgrade can be initiated by token holders.
contract MyUpgradedCollection is PermanentCreatorERC721 {
    
    constructor(address myV1Collection) CreatorERC721(myV1Collection, "MyCollection (V2)", "MC") {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollectionv2/metadata/";
    }

    /// TODO: Optionally, add additional utility/features here
}

/// @dev By inheriting PaidUnstakeCreatorERC721 and assigning the wrapped collection
/// address, a token upgrade can be initiated by token holders.  Upgraded tokens can
/// be downgraded to the prior version by paying a fee.
contract MyUpgradedCollection is PaidUnstakeCreatorERC721 {
    
    constructor(uint256 unstakePrice, address myV1Collection) PaidUnstakeCreatorERC721(unstakePrice, myV1Collection, "MyCollection (V2)", "MC") {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollectionv2/metadata/";
    }

    /// TODO: Optionally, add additional utility/features here
}

/// @dev By inheriting TimeLockedUnstakeCreatorERC721 and assigning the wrapped collection
/// address, a token upgrade can be initiated by token holders.  Upgraded tokens can
/// be downgraded to the prior version after a time lock expires.
contract MyUpgradedCollection is TimeLockedUnstakeCreatorERC721 {
    
    constructor(uint256 timelockSeconds, address myV1Collection) PaidUnstakeCreatorERC721(timelockSeconds, myV1Collection, "MyCollection (V2)", "MC") {}
    
    function _baseURI() internal view virtual override returns (string memory) {
        return "https://my.nft.com/mycollectionv2/metadata/";
    }

    /// TODO: Optionally, add additional utility/features here
}
```

## Security

This project is maintained by [Limit Break](https://limitbreak.com/).  The latest audit was completed in December 2022 on version 1.0.0.  However, we take no responsibility for your implementation decisions and any security problems you might experience.

## License

Creator Token Contracts is released under the [MIT License](LICENSE).

## FAQ

Q: Why is this library so simple, and why aren't more utility features provided out of the box?

A: To avoid feature creep to leave more room for creativity and innovation by other developers.  Instead of creating a lot of templates with a wide range of features, we focused on making it easy to adopt our powerful new features that will pave the way for other devlelopers to create cool new features and upgrade their old collections.

---

Q: Why use a whitelist instead of a blacklist?

A: Blacklists explicitly state who **is not allowed** to perform and action.  Whitelist explicitly state who **is allowed**.  Blacklists can only prevent an account from bypassing the intended software control flow after they are known.  This means time and gas fees must be spent monitoring for accounts that violate rules in order to keep a blacklist up to date.  With the proper incentive and motivation, there are ways to build marketplaces that can always stay ahead of a blacklist.  With a whitelist, however, new features can be built into specialized transfer operator contracts and transfer control flow logic is guaranteed to go through the intended set of contracts.  This creates new possibilities for features built around token transfer logic, including dynamic royalties for token collectors.

---

Q: Do I have to deploy and maintain my own whitelist?

A: Developers can choose to (a) deploy and maintain their own whitelist, (b) use a whitelist manageed by a DAO or other governance structure, or (c) use the official Limit Break whitelist.  The contract owner can also change which whitelist registry is in use, or even stop using a whitelist altogether at any time.

---

Q: When using a whitelist, can I transfer a token between two wallets I own?

A: Not directly, no.  But many marketplaces, including OpenSea, allow users to reserve a token to be sold to a specified buyer.  A functional work-around to achieve wallet to wallet transfers is to reserve the token for the inteneded wallet at a price of zero, or near zero to avoid paying royalties on a wallet to wallet transfer.

---

Q: As a developer, can I use CreatorERC721 tokens to chain NFT upgrades to release multiple versions?

A: Yes.  For example, the first version of a token could be upgraded to version two by wrapping a standard ERC-721 token with a Creator ERC721 token.  Down the line, the version 2 Creator ERC721 can be wrapped again into a version three Creator ERC721 token.  For each version, token holders decide whether or not they want to perform the upgrade by staking.  It is possible to downgrade all the way back to the original token by unstaking back down the upgrade chain.

---

Q: What impact will the wrapped tokens have with marketplace store fronts for the collections? Is there planned work and partnerships to improve this?

A: Limit Break has had exploratory conversations about the UX with some marketplaces.  Marketplaces should support a unified view of a collection that consists of multiple token contracts.  They should include the ability to hide tokens that are owned by address the contract owner/administrator specifies.  This would allow marketplace UIs to hide wrapped tokens and only display the upgraded wrapper tokens.  This unified view could unify the view of NFT floor price and trading activity across multipler versions of tokens.

---

Q: Who is on the Limit Break community whitelist? How does the list get updated?

A: Limit Break maintains a whitelist for internal use.  However, it is available for public use and projects that want to adopt the Limit Break whitelist are free to do so.  The current whitelist can be found [here](./documentation/LimitBreakCuratedWhitelist.md).
