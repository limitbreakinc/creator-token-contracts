// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "contracts/access/OwnableBasic.sol";
import "contracts/access/OwnableInitializable.sol";
import "contracts/erc721c/ERC721C.sol";
import "contracts/minting/AirdropMint.sol";

contract AirdropMintMock is ERC721C, AirdropMint, OwnableBasic {
    constructor(uint256 maxAirdropMints, uint256 maxSupply_, uint256 maxOwnerMints)
        ERC721OpenZeppelin("AidropMintMock", "AMM")
        AirdropMint(maxAirdropMints)
        MaxSupply(maxSupply_, maxOwnerMints)
    {}

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}

contract AirdropMintInitializableMock is ERC721CInitializable, AirdropMintInitializable, OwnableInitializable {
    constructor() ERC721("", "") {}

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}
