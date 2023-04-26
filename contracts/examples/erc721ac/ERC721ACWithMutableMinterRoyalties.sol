// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../erc721c/ERC721AC.sol";
import "../../programmable-royalties/MutableMinterRoyalties.sol";

contract ERC721ACWithMutableMinterRoyalties is ERC721AC, MutableMinterRoyalties {

    constructor(
        uint256 defaultRoyaltyFeeNumerator_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, MutableMinterRoyalties) returns (bool) {
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
