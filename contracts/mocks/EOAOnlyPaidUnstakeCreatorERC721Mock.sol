// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/eoa/EOAOnlyPaidUnstakeCreatorERC721.sol";

contract EOAOnlyPaidUnstakeCreatorERC721Mock is EOAOnlyPaidUnstakeCreatorERC721 {
    constructor(uint256 unrevealPrice_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) EOAOnlyPaidUnstakeCreatorERC721(unrevealPrice_, wrappedCollectionAddress_, name_, symbol_) {}
}