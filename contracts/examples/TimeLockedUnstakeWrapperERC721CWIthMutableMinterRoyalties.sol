// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../erc721c/presets/TimeLockedUnstakeWrapperERC721C.sol";
import "../programmable-royalties/MutableMinterRoyalties.sol";

contract TimeLockedUnstakeWrapperERC721CWithMutableMinterRoyalties is TimeLockedUnstakeWrapperERC721C, MutableMinterRoyalties {

    constructor(
        uint256 defaultRoyaltyFeeNumerator_,
        uint256 timelockSeconds_,
        address wrappedCollectionAddress_,
        address transferValidator_, 
        string memory name_,
        string memory symbol_) 
        TimeLockedUnstakeWrapperERC721C(timelockSeconds_, wrappedCollectionAddress_, transferValidator_, name_, symbol_) 
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
