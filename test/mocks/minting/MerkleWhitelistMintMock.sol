// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "contracts/access/OwnableBasic.sol";
import "contracts/access/OwnableInitializable.sol";
import "contracts/erc721c/ERC721C.sol";
import "contracts/minting/MerkleWhitelistMint.sol";

contract MerkleWhitelistMintMock is ERC721C, MerkleWhitelistMint, OwnableBasic {
    constructor(
        uint256 maxMerkleMints_,
        uint256 permittedNumberOfMerkleRootChanges_,
        uint256 maxSupply_,
        uint256 maxOwnerMints_
    )
        ERC721OpenZeppelin("MerkleWhitelistMintMock", "MWM")
        MerkleWhitelistMint(maxMerkleMints_, permittedNumberOfMerkleRootChanges_)
        MaxSupply(maxSupply_, maxOwnerMints_)
    {}

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}

contract MerkleWhitelistMintInitializableMock is
    ERC721CInitializable,
    MerkleWhitelistMintInitializable,
    OwnableInitializable
{
    constructor() ERC721("", "") {}

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}
