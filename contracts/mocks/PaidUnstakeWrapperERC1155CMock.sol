// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc1155c/presets/PaidUnstakeWrapperERC1155C.sol";

contract PaidUnstakeWrapperERC1155CMock is PaidUnstakeWrapperERC1155C {
    constructor(
        uint256 unrevealPrice_, 
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory uri_) 
        PaidUnstakeWrapperERC1155C(unrevealPrice_, wrappedCollectionAddress_, transferValidator_, uri_) {}
}