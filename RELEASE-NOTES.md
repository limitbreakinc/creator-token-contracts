## 1.1.2 (2023-06-15)

* Add README text to clarify this library is not compatible with Upgradeable contracts.
* Add documentation comments to clarify merkle mint mix-in usage.
* Fix pragma locked to 0.8.9

## 1.1.1 (2023-05-22)

* Refactored code to support either fully constructed or cloned contracts.
* Implemented EIP-1167 for payment splitter cloning to streamline the shared royalties mix-in.
* Testing code coverage improvements

### Upgrade Steps
* Use npm or yarn to install creator-token-contracts at v1.1.1

## 1.1.0 (2023-05-08)

* Formalized creator token standards, added sample programmable royalty mix-ins, a marketplace helper mix-in, and more!

### Upgrade Steps
* Use npm or yarn to install creator-token-contracts at v1.1.0

### Breaking Changes
* Replaced WhitelistedTransferERC721 with ERC721C
* Replaced CreatorERC721/EOAOnlyCreatorERC721 with ERC721CW
* Removed external Whitelist Registry contracts in favor of CreatorTokenTransferValidator

### New Features
* Added AdventureERC721 for community use
* Added CreatorTokenTransferValidator contract - a central contract where ERC721-C collections can configure their desired transfer security level and transfer whitelist
* Formalized creator token interfaces
* ERC721-C
* ERC721-CW (Wrapper Token For ERC721)
* ERC1155-C
* ERC1155-CW (Wrapper Token For ERC1155)
* AdventureERC721-C
* AdventureERC721-CW (Adventure-compatible ERC721-CW wrapper token)
* ERC721-AC (Azuki ERC721-A with creator token features)
* Sample programmable royalty mix-ins
* Onchain Royalty Order Fulfillment Mix-In for Marketplaces
* Numerous examples of how to use these contracts together