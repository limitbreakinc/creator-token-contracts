// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "contracts/access/OwnableBasic.sol";
import "contracts/erc721c/ERC721C.sol";
import "contracts/token/erc721/MetadataURI.sol";

abstract contract ERC721CMetadata is 
    OwnableBasic, 
    MetadataURI, 
    ERC721C {
    using Strings for uint256;

    error AdventureFreeNFT__NonexistentToken();

    constructor(string memory name_, string memory symbol_)
    Ownable() 
    ERC721OpenZeppelin(name_, symbol_) {}

    /// @notice Returns tokenURI if baseURI is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(!_exists(tokenId)) {
            revert AdventureFreeNFT__NonexistentToken();
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffixURI))
            : "";
    }

    /// @dev Required to return baseTokenURI for tokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}