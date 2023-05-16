// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/access/OwnableInitializable.sol";
import "../../contracts/erc721c/AdventureERC721C.sol";

contract AdventureERC721CMock is OwnableBasic, AdventureERC721C {
    
    constructor() AdventureERC721(100) ERC721OpenZeppelin("ERC-721C Mock", "MOCK") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract AdventureERC721CInitializableMock is OwnableInitializable, AdventureERC721CInitializable {
    
    constructor() ERC721("", "") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}