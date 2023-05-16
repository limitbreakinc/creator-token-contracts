// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../AdventureERC721CMetadata.sol";
import "contracts/minting/AirdropMint.sol";
import "contracts/programmable-royalties/MutableMinterRoyalties.sol";

contract AirdropMock is 
    AdventureERC721CMetadata, 
    AirdropMint,
    MutableMinterRoyalties {

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 maxSimultaneousQuests_, 
        uint256 maxSupply_, 
        uint256 maxOwnerMints_,
        uint256 maxAirdropMints_,
        uint96 defaultRoyaltyFeeNumerator_) 
    AdventureERC721CMetadata(name_, symbol_, maxSimultaneousQuests_) 
    MaxSupply(maxSupply_, maxOwnerMints_)
    AirdropMint(maxAirdropMints_) 
    MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, MutableMinterRoyaltiesBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        _mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}