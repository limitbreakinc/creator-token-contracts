// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../ERC721CMetadataInitializable.sol";
import "contracts/minting/AirdropMint.sol";
import "contracts/programmable-royalties/MinterCreatorSharedRoyalties.sol";

contract AirdropMock is
    ERC721CMetadataInitializable,
    AirdropMintInitializable,
    MinterCreatorSharedRoyaltiesInitializable
{
    constructor() ERC721("", "") {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721CInitializable, MinterCreatorSharedRoyaltiesBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        _mint(to, tokenId);
    }
}
