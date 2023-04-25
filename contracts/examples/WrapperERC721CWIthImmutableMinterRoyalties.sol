// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/extensions/WrapperERC721C.sol";
import "../programmable-royalties/ImmutableMinterRoyalties.sol";

contract WrapperERC721CWithImmutableMinterRoyalties is WrapperERC721C, ImmutableMinterRoyalties {

    constructor(
        uint256 royaltyFeeNumerator_,
        address wrappedCollectionAddress_,
        address transferValidator_, 
        string memory name_,
        string memory symbol_) 
        WrapperERC721C(wrappedCollectionAddress_, transferValidator_, name_, symbol_) 
        ImmutableMinterRoyalties(royaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, ImmutableMinterRoyalties) returns (bool) {
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
