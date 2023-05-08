// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc721c/AdventureERC721C.sol";

contract AdventureERC721CMock is AdventureERC721C {
    
    constructor() AdventureERC721C(100, "ERC-721C Mock", "MOCK") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}