// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/presets/PermanentWrapperERC721C.sol";
import "../programmable-royalties/MinterRoyaltiesReassignableRightsNFT.sol";

contract PermanentWrapperERC721CWithReassignableMinterRoyalties is PermanentWrapperERC721C, MinterRoyaltiesReassignableRightsNFT {

    constructor(
        uint256 royaltyFeeNumerator_,
        address royaltyRightsNFTReference_,
        address wrappedCollectionAddress_,
        address transferValidator_, 
        string memory name_,
        string memory symbol_) 
        ERC721CW(wrappedCollectionAddress_, transferValidator_, name_, symbol_) 
        MinterRoyaltiesReassignableRightsNFT(royaltyFeeNumerator_, royaltyRightsNFTReference_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, MinterRoyaltiesReassignableRightsNFT) returns (bool) {
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
