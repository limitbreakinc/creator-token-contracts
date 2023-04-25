// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc721c/presets/ERC721CWPaidUnstake.sol";

contract PaidUnstakeWrapperERC721CMock is ERC721CWPaidUnstake {
    constructor(
        uint256 unrevealPrice_, 
        address wrappedCollectionAddress_, 
        address transferValidator_,
        string memory name_, 
        string memory symbol_) 
        ERC721CWPaidUnstake(unrevealPrice_, wrappedCollectionAddress_, transferValidator_, name_, symbol_) {}
}