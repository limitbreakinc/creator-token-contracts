// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnableBasic.sol";
import "../../erc721c/ERC721AC.sol";
import "../../programmable-royalties/BasicRoyalties.sol";

/**
 * @title ERC721ACWithBasicRoyalties
 * @author Limit Break, Inc.
 * @notice Extension of ERC721AC that adds basic royalties support.
 * @dev These contracts are intended for example use and are not intended for production deployments as-is.
 */
contract ERC721ACWithBasicRoyalties is OwnableBasic, ERC721AC, BasicRoyalties {

    constructor(
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function safeMint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
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
