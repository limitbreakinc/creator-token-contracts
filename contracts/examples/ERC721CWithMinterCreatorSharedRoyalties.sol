// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/ERC721C.sol";
import "../programmable-royalties/MinterCreatorSharedRoyalties.sol";

contract ERC721CWithMinterCreatorSharedRoyalties is ERC721C, MinterCreatorSharedRoyalties {

    constructor(
        uint256 royaltyFeeNumerator_,
        uint256 minterShares_,
        uint256 creatorShares_,
        address creator_,
        address transferValidator_, 
        string memory name_,
        string memory symbol_) 
        ERC721C(transferValidator_, name_, symbol_) 
        MinterCreatorSharedRoyalties(royaltyFeeNumerator_, minterShares_, creatorShares_, creator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, MinterCreatorSharedRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _onMinted(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}
