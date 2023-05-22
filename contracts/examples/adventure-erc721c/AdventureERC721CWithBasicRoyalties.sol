// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../erc721c/AdventureERC721C.sol";
import "../../programmable-royalties/BasicRoyalties.sol";

/**
 * @title AdventureERC721CWithBasicRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of AdventureERC721C that adds basic royalties support.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract AdventureERC721CWithBasicRoyalties is OwnableBasic, AdventureERC721C, BasicRoyalties {

    constructor(
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        uint256 maxSimultaneousQuests_,
        string memory name_,
        string memory symbol_) 
        AdventureERC721(maxSimultaneousQuests_)
        ERC721OpenZeppelin(name_, symbol_) 
        BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureERC721C, ERC2981) returns (bool) {
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

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _requireCallerIsContractOwner();
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
}
