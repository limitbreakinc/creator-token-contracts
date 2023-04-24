// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc721c/presets/PermanentWrapperERC721C.sol";

contract PermanentWrapperERC721CMock is PermanentWrapperERC721C {
    constructor(
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory name_, 
        string memory symbol_) 
        WrapperERC721C(wrappedCollectionAddress_, transferValidator_, name_, symbol_) {}
}