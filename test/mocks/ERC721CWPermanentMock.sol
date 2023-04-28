// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc721c/presets/ERC721CWPermanent.sol";

contract ERC721CWPermanentMock is ERC721CWPermanent {
    constructor(address wrappedCollectionAddress_) ERC721CW(wrappedCollectionAddress_, "ERC-721C Mock", "MOCK") {}

    function mint(address /*to*/, uint256 tokenId) external {
        stake(tokenId);
    }
}