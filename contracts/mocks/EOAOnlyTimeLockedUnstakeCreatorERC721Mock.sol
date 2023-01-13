// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/eoa/EOAOnlyTimeLockedUnstakeCreatorERC721.sol";

contract EOAOnlyTimeLockedUnstakeCreatorERC721Mock is EOAOnlyTimeLockedUnstakeCreatorERC721 {
    constructor(uint256 timelockSeconds_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) EOAOnlyTimeLockedUnstakeCreatorERC721(timelockSeconds_, wrappedCollectionAddress_, name_, symbol_) {}
}