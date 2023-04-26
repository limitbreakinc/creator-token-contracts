// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc721c/presets/ERC721CWTimeLockedUnstake.sol";

contract TimeLockedUnstakeWrapperERC721CMock is ERC721CWTimeLockedUnstake {
    constructor(
        uint256 timelockSeconds_, 
        address wrappedCollectionAddress_, 
        string memory name_, 
        string memory symbol_) 
        ERC721CWTimeLockedUnstake(
            timelockSeconds_, 
            wrappedCollectionAddress_, 
            name_, 
            symbol_) {}
}