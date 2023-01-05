// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/TimeLockedUnstakeCreatorERC721.sol";

contract TimeLockedUnstakeCreatorERC721Mock is TimeLockedUnstakeCreatorERC721 {
    constructor(uint256 timelockSeconds_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) TimeLockedUnstakeCreatorERC721(timelockSeconds_, wrappedCollectionAddress_, name_, symbol_) {}
}