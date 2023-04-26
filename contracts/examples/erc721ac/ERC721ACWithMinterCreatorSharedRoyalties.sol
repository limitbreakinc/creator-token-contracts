// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../erc721c/ERC721AC.sol";
import "../../programmable-royalties/MinterCreatorSharedRoyalties.sol";

contract ERC721ACWithMinterCreatorSharedRoyalties is ERC721AC, MinterCreatorSharedRoyalties {

    constructor(
        uint256 royaltyFeeNumerator_,
        uint256 minterShares_,
        uint256 creatorShares_,
        address creator_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        MinterCreatorSharedRoyalties(royaltyFeeNumerator_, minterShares_, creatorShares_, creator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, MinterCreatorSharedRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        super._mint(to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        super._safeMint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}
