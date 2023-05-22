// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../erc721c/ERC721AC.sol";
import "../../programmable-royalties/MinterRoyaltiesReassignableRightsNFT.sol";

/**
 * @title ERC721ACWithReassignableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of ERC721AC that creates a separate reassignable royalty rights NFT for each token.
 *         The reassignable royalty rights NFT is freely tradeable, abstracting royalty rights from the token itself.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract ERC721ACWithReassignableMinterRoyalties is OwnableBasic, ERC721AC, MinterRoyaltiesReassignableRightsNFT {

    constructor(
        uint256 royaltyFeeNumerator_,
        address royaltyRightsNFTReference_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        MinterRoyaltiesReassignableRightsNFT(royaltyFeeNumerator_, royaltyRightsNFTReference_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, MinterRoyaltiesReassignableRightsNFT) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function safeMint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
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
