// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/eoa/EOAOnlyPermanentCreatorERC721.sol";

contract EOAOnlyPermanentCreatorERC721Mock is EOAOnlyPermanentCreatorERC721 {
    constructor(address wrappedCollectionAddress_, string memory name_, string memory symbol_) CreatorERC721(wrappedCollectionAddress_, name_, symbol_) {}
}