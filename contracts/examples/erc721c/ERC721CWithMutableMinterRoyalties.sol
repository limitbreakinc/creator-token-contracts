// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../access/OwnableInitializable.sol";
import "../../erc721c/ERC721C.sol";
import "../../programmable-royalties/MutableMinterRoyalties.sol";

/**
 * @title ERC721CWithMutableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of ERC721C that allows for minters to receive royalties on the tokens they mint.
 *         The royalty fee is mutable and settable by the owner of each minted token.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract ERC721CWithMutableMinterRoyalties is OwnableBasic, ERC721C, MutableMinterRoyalties {

    constructor(
        uint96 defaultRoyaltyFeeNumerator_,
        string memory name_,
        string memory symbol_) 
        ERC721OpenZeppelin(name_, symbol_) 
        MutableMinterRoyalties(defaultRoyaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721C, MutableMinterRoyaltiesBase) returns (bool) {
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
 * @title ERC721CWithMutableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Initializable extension of ERC721C that allows for minters to receive royalties on the tokens they mint.
 *         The royalty fee is mutable and settable by the owner of each minted token. Allows for EIP-1167 clones.
 */
contract ERC721CWithMutableMinterRoyaltiesInitializable is OwnableInitializable, ERC721CInitializable, MutableMinterRoyaltiesInitializable {

    constructor() ERC721("", "") {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CInitializable, MutableMinterRoyaltiesBase) returns (bool) {
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