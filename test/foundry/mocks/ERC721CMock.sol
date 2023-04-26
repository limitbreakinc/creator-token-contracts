// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../../contracts/erc721c/ERC721C.sol";

contract ERC721CMock is ERC721C {
    
    constructor() ERC721C("ERC-721C Mock", "MOCK") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}