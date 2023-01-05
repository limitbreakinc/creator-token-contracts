// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../presets/PaidUnstakeCreatorERC721.sol";

contract PaidUnstakeCreatorERC721Mock is PaidUnstakeCreatorERC721 {
    constructor(uint256 unrevealPrice_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) PaidUnstakeCreatorERC721(unrevealPrice_, wrappedCollectionAddress_, name_, symbol_) {}
}