// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc1155c/presets/PermanentWrapperERC1155C.sol";

contract PermanentWrapperERC1155CMock is PermanentWrapperERC1155C {
    constructor(
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory uri_) 
        ERC1155CW(wrappedCollectionAddress_, transferValidator_, uri_) {}
}