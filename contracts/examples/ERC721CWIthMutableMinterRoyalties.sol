// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/ERC721C.sol";
import "../programmable-royalties/MutableMinterRoyalties.sol";

contract ERC721CWithMutableMinterRoyalties is ERC721C, MutableMinterRoyalties {

    constructor(
        uint256 defaultRoyaltyFeeNumerator_,
        address transferValidator_, 
        string memory name_,
        string memory symbol_) 
        ERC721C(transferValidator_, name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, MutableMinterRoyalties) returns (bool) {
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
