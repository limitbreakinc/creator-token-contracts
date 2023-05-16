// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../AdventureERC721CMetadata.sol";
import "contracts/minting/AirdropMint.sol";
import "contracts/programmable-royalties/BasicRoyalties.sol";

contract AirdropMock is 
    AdventureERC721CMetadata, 
    AirdropMint,
    BasicRoyalties {

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 maxSimultaneousQuests_, 
        uint256 maxSupply_, 
        uint256 maxOwnerMints_,
        uint256 maxAirdropMints_,
        address royaltyReceiver_, 
        uint96 royaltyFeeNumerator_) 
    AdventureERC721CMetadata(name_, symbol_, maxSimultaneousQuests_) 
    MaxSupply(maxSupply_, maxOwnerMints_)
    AirdropMint(maxAirdropMints_) 
    BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }
}