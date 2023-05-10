// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../access/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title InitializableERC721
 * @author Limit Break, Inc.
 * @notice Wraps OpenZeppelin ERC721 implementation and makes it compatible with EIP-1167.
 * @dev Because OpenZeppelin's `_name` and `_symbol` storage variables are private and inaccessible, 
 * this contract defines two new storage variables `_contractName` and `_contractSymbol` and returns them
 * from the `name()` and `symbol()` functions instead.
 */
abstract contract InitializableERC721 is InitializableOwnable, ERC721 {

    error InitializableERC721__AlreadyInitializedERC721();

    /// @notice Specifies whether or not the contract is initialized
    bool private initializedERC721;

    // Token name
    string internal _contractName;

    // Token symbol
    string internal _contractSymbol;

    /// @dev Initializes parameters of ERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeERC721(string memory name_, string memory symbol_) public onlyOwner {
        if(initializedERC721) {
            revert InitializableERC721__AlreadyInitializedERC721();
        }

        _contractName = name_;
        _contractSymbol = symbol_;

        initializedERC721 = true;
    }

    function name() public view virtual override returns (string memory) {
        return _contractName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _contractSymbol;
    }
}
