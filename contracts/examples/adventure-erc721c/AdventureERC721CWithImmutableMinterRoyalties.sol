// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../erc721c/AdventureERC721C.sol";
import "../../programmable-royalties/ImmutableMinterRoyalties.sol";

/**
 * @title AdventureERC721CWithImmutableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of AdventureERC721C that allows for minters to receive royalties on the tokens they mint.
 *         The royalty fee is immutable and set at contract creation.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract AdventureERC721CWithImmutableMinterRoyalties is OwnableBasic, AdventureERC721C, ImmutableMinterRoyalties {

    constructor(
        uint256 royaltyFeeNumerator_,
        uint256 maxSimultaneousQuests_,
        string memory name_,
        string memory symbol_) 
        AdventureERC721(maxSimultaneousQuests_)
        ERC721OpenZeppelin(name_, symbol_) 
        ImmutableMinterRoyalties(royaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, ImmutableMinterRoyaltiesBase) returns (bool) {
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
