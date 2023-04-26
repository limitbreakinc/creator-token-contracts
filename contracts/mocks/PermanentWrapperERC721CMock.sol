// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc721c/presets/ERC721CWPermanent.sol";

contract ERC721CWPermanentMock is ERC721CWPermanent {
    constructor(
        address wrappedCollectionAddress_, 
        string memory name_, 
        string memory symbol_) 
        ERC721CW(wrappedCollectionAddress_, name_, symbol_) {}
}