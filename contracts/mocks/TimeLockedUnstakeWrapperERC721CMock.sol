// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc721c/presets/TimeLockedUnstakeWrapperERC721C.sol";

contract TimeLockedUnstakeWrapperERC721CMock is TimeLockedUnstakeWrapperERC721C {
    constructor(
        uint256 timelockSeconds_, 
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory name_, 
        string memory symbol_) 
        TimeLockedUnstakeWrapperERC721C(
            timelockSeconds_, 
            wrappedCollectionAddress_, 
            transferValidator_, 
            name_, 
            symbol_) {}
}