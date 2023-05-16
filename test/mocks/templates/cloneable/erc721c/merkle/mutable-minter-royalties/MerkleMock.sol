// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../ERC721CMetadataInitializable.sol";
import "contracts/minting/MerkleWhitelistMint.sol";
import "contracts/programmable-royalties/MutableMinterRoyalties.sol";

contract MerkleMock is 
    ERC721CMetadataInitializable, 
    MerkleWhitelistMintInitializable,
    MutableMinterRoyaltiesInitializable {

    constructor() ERC721("", "") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CInitializable, MutableMinterRoyaltiesBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        _mint(to, tokenId);
    }
}