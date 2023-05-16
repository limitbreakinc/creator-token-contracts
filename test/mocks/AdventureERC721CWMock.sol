// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/access/OwnableInitializable.sol";
import "../../contracts/erc721c/extensions/AdventureERC721CW.sol";

contract AdventureERC721CWMock is OwnableBasic, AdventureERC721CW {
    
    constructor(address wrappedCollectionAddress_) 
    AdventureERC721CW(wrappedCollectionAddress_)
    AdventureERC721(100)
    ERC721OpenZeppelin("ERC-721C Mock", "MOCK") {}

    function mint(address /*to*/, uint256 tokenId) external {
        stake(tokenId);
    }
}

contract AdventureERC721CWInitializableMock is OwnableInitializable, AdventureERC721CWInitializable {
    
    constructor() ERC721("", "") {}

    function mint(address /*to*/, uint256 tokenId) external {
        stake(tokenId);
    }
}