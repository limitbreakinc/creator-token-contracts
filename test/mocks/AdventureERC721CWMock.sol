// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc721c/extensions/AdventureERC721CW.sol";

contract AdventureERC721CWMock is AdventureERC721CW {
    
    constructor(address wrappedCollectionAddress_) AdventureERC721CW(wrappedCollectionAddress_, 100, "ERC-721C Mock", "MOCK") {}

    function mint(address /*to*/, uint256 tokenId) external {
        stake(tokenId);
    }
}