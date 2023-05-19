// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../AdventureERC721CMetadata.sol";
import "contracts/minting/MerkleWhitelistMint.sol";
import "contracts/programmable-royalties/MinterCreatorSharedRoyalties.sol";

contract MerkleMock is AdventureERC721CMetadata, MerkleWhitelistMint, MinterCreatorSharedRoyalties {
    struct SharedRoyaltyConfiguration {
        uint256 royaltyFeeNumerator;
        uint256 minterShares;
        uint256 creatorShares;
        address creator;
        address paymentSplitter;
    }

    struct MerkleMintConfiguration {
        uint256 maxMerkleMints;
        uint256 permittedNumberOfMerkleRootChanges;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSimultaneousQuests_,
        uint256 maxSupply_,
        uint256 maxOwnerMints_,
        MerkleMintConfiguration memory MerkleMintConfiguration_,
        SharedRoyaltyConfiguration memory sharedRoyaltyConfiguration_
    )
        AdventureERC721CMetadata(name_, symbol_, maxSimultaneousQuests_)
        MaxSupply(maxSupply_, maxOwnerMints_)
        MerkleWhitelistMint(
            MerkleMintConfiguration_.maxMerkleMints,
            MerkleMintConfiguration_.permittedNumberOfMerkleRootChanges
        )
        MinterCreatorSharedRoyalties(
            sharedRoyaltyConfiguration_.royaltyFeeNumerator,
            sharedRoyaltyConfiguration_.minterShares,
            sharedRoyaltyConfiguration_.creatorShares,
            sharedRoyaltyConfiguration_.creator,
            sharedRoyaltyConfiguration_.paymentSplitter
        )
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdventureERC721C, MinterCreatorSharedRoyaltiesBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _onMinted(to, tokenId);
        _mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _onBurned(tokenId);
    }
}
