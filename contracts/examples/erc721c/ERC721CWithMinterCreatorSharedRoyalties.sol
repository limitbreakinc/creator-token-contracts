// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../access/OwnableInitializable.sol";
import "../../erc721c/ERC721C.sol";
import "../../programmable-royalties/MinterCreatorSharedRoyalties.sol";

/**
 * @title ERC721CWithMinterCreatorSharedRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of ERC721C that allows for minters and creators to receive a split of royalties on the tokens minted.
 *         The royalty fee and percent split is immutable and set at contract creation.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract ERC721CWithMinterCreatorSharedRoyalties is OwnableBasic, ERC721C, MinterCreatorSharedRoyalties {

    constructor(
        uint256 royaltyFeeNumerator_,
        uint256 minterShares_,
        uint256 creatorShares_,
        address creator_,
        address paymentSplitterReference_,
        string memory name_,
        string memory symbol_) 
        ERC721OpenZeppelin(name_, symbol_) 
        MinterCreatorSharedRoyalties(royaltyFeeNumerator_, minterShares_, creatorShares_, creator_, paymentSplitterReference_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, MinterCreatorSharedRoyaltiesBase) returns (bool) {
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

/**
 * @title ERC721CWithMinterCreatorSharedRoyaltiesInitializable
 * @author Limit Break, Inc.
 * @notice Initializable extension of ERC721C that allows for minters and creators to receive a split of royalties on the tokens minted.
 *         The royalty fee and percent split is immutable and set at contract creation. Allows for EIP-1167 clones.
 */
contract ERC721CWithMinterCreatorSharedRoyaltiesInitializable is OwnableInitializable, ERC721CInitializable, MinterCreatorSharedRoyaltiesInitializable {

    constructor() ERC721("", "") {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CInitializable, MinterCreatorSharedRoyaltiesBase) returns (bool) {
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
