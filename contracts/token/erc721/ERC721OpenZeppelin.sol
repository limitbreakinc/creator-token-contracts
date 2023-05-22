// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../access/OwnablePermissions.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721OpenZeppelinBase is ERC721 {

    // Token name
    string internal _contractName;

    // Token symbol
    string internal _contractSymbol;

    function name() public view virtual override returns (string memory) {
        return _contractName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _contractSymbol;
    }

    function _setNameAndSymbol(string memory name_, string memory symbol_) internal {
        _contractName = name_;
        _contractSymbol = symbol_;
    }
}

abstract contract ERC721OpenZeppelin is ERC721OpenZeppelinBase {
    constructor(string memory name_, string memory symbol_) ERC721("", "") {
        _setNameAndSymbol(name_, symbol_);
    }
}

abstract contract ERC721OpenZeppelinInitializable is OwnablePermissions, ERC721OpenZeppelinBase {

    error ERC721OpenZeppelinInitializable__AlreadyInitializedERC721();

    /// @notice Specifies whether or not the contract is initialized
    bool private _erc721Initialized;

    /// @dev Initializes parameters of ERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeERC721(string memory name_, string memory symbol_) public {
        _requireCallerIsContractOwner();

        if(_erc721Initialized) {
            revert ERC721OpenZeppelinInitializable__AlreadyInitializedERC721();
        }

        _erc721Initialized = true;

        _setNameAndSymbol(name_, symbol_);
    }
}
