// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/PaidUnstakeWrapperERC721C.sol";

contract PaidUnstakeWrapperERC721CMock is PaidUnstakeWrapperERC721C {
    constructor(
        uint256 unrevealPrice_, 
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory name_, 
        string memory symbol_) 
        PaidUnstakeWrapperERC721C(unrevealPrice_, wrappedCollectionAddress_, transferValidator_, name_, symbol_) {}
}