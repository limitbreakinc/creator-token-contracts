// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../erc721c/presets/ERC721CWTimeLockedUnstake.sol";
import "../../programmable-royalties/MutableMinterRoyalties.sol";

contract ERC721CWTimeLockedUnstakeWithMutableMinterRoyalties is ERC721CWTimeLockedUnstake, MutableMinterRoyalties {

    constructor(
        uint96 defaultRoyaltyFeeNumerator_,
        uint256 timelockSeconds_,
        address wrappedCollectionAddress_,
        string memory name_,
        string memory symbol_) 
        ERC721CWTimeLockedUnstake(timelockSeconds_, wrappedCollectionAddress_, name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, MutableMinterRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}
