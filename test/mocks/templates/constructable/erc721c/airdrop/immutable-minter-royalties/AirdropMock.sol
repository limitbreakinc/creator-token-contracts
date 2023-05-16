// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../ERC721CMetadata.sol";
import "contracts/minting/AirdropMint.sol";
import "contracts/programmable-royalties/ImmutableMinterRoyalties.sol";

contract AirdropMock is 
    ERC721CMetadata, 
    AirdropMint,
    ImmutableMinterRoyalties {

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 maxSupply_, 
        uint256 maxOwnerMints_,
        uint256 maxAirdropMints_,
        uint256 royaltyFeeNumerator_) 
    ERC721CMetadata(name_, symbol_) 
    MaxSupply(maxSupply_, maxOwnerMints_)
    AirdropMint(maxAirdropMints_) 
    ImmutableMinterRoyalties(royaltyFeeNumerator_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, ImmutableMinterRoyaltiesBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        _mint(to, tokenId);
    }
}