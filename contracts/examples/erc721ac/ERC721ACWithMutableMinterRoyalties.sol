// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../erc721c/ERC721AC.sol";
import "../../programmable-royalties/MutableMinterRoyalties.sol";

contract ERC721ACWithMutableMinterRoyalties is ERC721AC, MutableMinterRoyalties {

    constructor(
        uint96 defaultRoyaltyFeeNumerator_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, MutableMinterRoyalties) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function safeMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _mint(address to, uint256 quantity) internal virtual override {
        uint256 nextTokenId = _nextTokenId();

        for (uint256 i = 0; i < quantity;) {
            _onMinted(to, nextTokenId + i);
            
            unchecked {
                ++i;
            }
        }

        super._mint(to, quantity);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
