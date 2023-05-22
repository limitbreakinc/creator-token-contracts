// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../erc721c/AdventureERC721C.sol";
import "../../programmable-royalties/MinterRoyaltiesReassignableRightsNFT.sol";

/**
 * @title ERC721CWithMutableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of AdventureERC721C that creates a separate reassignable royalty rights NFT for each token.
 *         The reassignable royalty rights NFT is freely tradeable, abstracting royalty rights from the token itself.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract AdventureERC721CWithReassignableMinterRoyalties is OwnableBasic, AdventureERC721C, MinterRoyaltiesReassignableRightsNFT {

    constructor(
        uint256 royaltyFeeNumerator_,
        address royaltyRightsNFTReference_,
        uint256 maxSimultaneousQuests_,
        string memory name_,
        string memory symbol_) 
        AdventureERC721(maxSimultaneousQuests_)
        ERC721OpenZeppelin(name_, symbol_) 
        MinterRoyaltiesReassignableRightsNFT(royaltyFeeNumerator_, royaltyRightsNFTReference_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, MinterRoyaltiesReassignableRightsNFT) returns (bool) {
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

    function _mint(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}
