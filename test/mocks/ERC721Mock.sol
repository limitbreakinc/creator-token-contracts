// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is Ownable, ERC721 {
    
    string public myBaseURI;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mintTo(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}