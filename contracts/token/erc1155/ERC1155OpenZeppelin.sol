// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../access/OwnablePermissions.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

abstract contract ERC1155OpenZeppelinBase is ERC1155 {

}

abstract contract ERC1155OpenZeppelin is ERC1155OpenZeppelinBase {
    constructor(string memory uri_) ERC1155(uri_) {}
}

abstract contract ERC1155OpenZeppelinInitializable is OwnablePermissions, ERC1155OpenZeppelinBase {

    error ERC1155OpenZeppelinInitializable__AlreadyInitializedERC1155();

    bool private _erc1155Initialized;

    function initializeERC1155(string memory uri_) public {
        _requireCallerIsContractOwner();

        if(_erc1155Initialized) {
            revert ERC1155OpenZeppelinInitializable__AlreadyInitializedERC1155();
        }

        _erc1155Initialized = true;

        _setURI(uri_);
    }
}