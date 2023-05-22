// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/CreatorTokenBase.sol";
import "../adventures/AdventureERC721.sol";

/**
 * @title AdventureERC721C
 * @author Limit Break, Inc.
 * @notice Extends Limit Break's AdventureERC721 implementation with Creator Token functionality, which
 *         allows the contract owner to update the transfer validation logic by managing a security policy in
 *         an external transfer validation security policy registry.  See {CreatorTokenTransferValidator}.
 */
abstract contract AdventureERC721C is AdventureERC721, CreatorTokenBase {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Ties the adventure erc721 _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {

        uint256 tokenId;
        for (uint256 i = 0; i < batchSize;) {
            tokenId = firstTokenId + i;
            if(blockingQuestCounts[tokenId] > 0) {
                revert AdventureERC721__AnActiveQuestIsPreventingTransfers();
            }

            if(transferType == TRANSFERRING_VIA_ERC721) {
                _validateBeforeTransfer(from, to, tokenId);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the adventure erc721 _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }
}


/**
 * @title AdventureERC721CInitializable
 * @author Limit Break, Inc.
 * @notice Initializable implementation of the AdventureERC721C contract to allow for EIP-1167 clones.
 */
abstract contract AdventureERC721CInitializable is AdventureERC721Initializable, CreatorTokenBase {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Ties the adventure erc721 _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {

        uint256 tokenId;
        for (uint256 i = 0; i < batchSize;) {
            tokenId = firstTokenId + i;
            if(blockingQuestCounts[tokenId] > 0) {
                revert AdventureERC721__AnActiveQuestIsPreventingTransfers();
            }

            if(transferType == TRANSFERRING_VIA_ERC721) {
                _validateBeforeTransfer(from, to, tokenId);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the adventure erc721 _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }
}