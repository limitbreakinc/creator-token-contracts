// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/CreatorTokenBase.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title ERC721C
 * @author Limit Break, Inc.
 * @notice 
 */
abstract contract ERC1155C is ERC1155, CreatorTokenBase {
    
    constructor(address transferValidator_, string memory uri_) 
    CreatorTokenBase(transferValidator_)
    ERC1155(uri_) {
        setTransferValidator(transferValidator_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length;) {
            _validateBeforeTransfer(from, to, ids[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length;) {
            _validateAfterTransfer(from, to, ids[i]);

            unchecked {
                ++i;
            }
        }
    }
}
