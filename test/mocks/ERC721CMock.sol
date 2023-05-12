// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/erc721c/ERC721C.sol";

contract ERC721CMock is OwnableBasic, ERC721C {
    
    constructor() ERC721OpenZeppelin("ERC-721C Mock", "MOCK") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}