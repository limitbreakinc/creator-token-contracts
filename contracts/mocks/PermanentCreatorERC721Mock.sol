// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/PermanentCreatorERC721.sol";

contract PermanentCreatorERC721Mock is PermanentCreatorERC721 {
    constructor(address wrappedCollectionAddress_, string memory name_, string memory symbol_) CreatorERC721(wrappedCollectionAddress_, name_, symbol_) {}
}