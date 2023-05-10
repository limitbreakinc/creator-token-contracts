// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../access/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title InitializableERC721
 * @author Limit Break, Inc.
 * @notice Wraps OpenZeppelin ERC721 implementation and makes it compatible with EIP-1167.
 * @dev Because OpenZeppelin's `_name` and `_symbol` storage variables are private and inaccessible, 
 * this contract defines two new storage variables `_contractName` and `_contractSymbol` and returns them
 * from the `name()` and `symbol()` functions instead.
 */
abstract contract InitializableERC1155 is InitializableOwnable, ERC1155 {

    error InitializableERC1155__AlreadyInitializedERC1155();

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedERC1155;

    /// @dev Initializes parameters of ERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeERC1155(string memory uri_) public onlyOwner {
        if(initializedERC1155) {
            revert InitializableERC1155__AlreadyInitializedERC1155();
        }

        _setURI(uri_);

        initializedERC1155 = true;
    }
}
