// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../access/OwnablePermissions.sol";

abstract contract MetadataURI is OwnablePermissions {

    /// @dev Base token uri
    string public baseTokenURI;

    /// @dev Token uri suffix/extension
    string public suffixURI;

    /// @dev Emitted when base URI is set.
    event BaseURISet(string baseTokenURI);

    /// @dev Emitted when suffix URI is set.
    event SuffixURISet(string suffixURI);

    /// @notice Sets base URI
    function setBaseURI(string memory baseTokenURI_) public {
        _requireCallerIsContractOwner();
        baseTokenURI = baseTokenURI_;
        emit BaseURISet(baseTokenURI_);
    }

    /// @notice Sets suffix URI
    function setSuffixURI(string memory suffixURI_) public {
        _requireCallerIsContractOwner();
        suffixURI = suffixURI_;
        emit SuffixURISet(suffixURI_);
    }
}

abstract contract MetadataURIInitializable is MetadataURI {
    error MetadataURIInitializable__URIAlreadyInitialized();

    bool private _uriInitialized;

    /// @dev Initializes parameters of tokens with uri values.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeURI(string memory baseURI_, string memory suffixURI_) public {
        _requireCallerIsContractOwner();

        if(_uriInitialized) {
            revert MetadataURIInitializable__URIAlreadyInitialized();
        }

        _uriInitialized = true;

        baseTokenURI = baseURI_;
        emit BaseURISet(baseURI_);

        suffixURI = suffixURI_;
        emit SuffixURISet(suffixURI_);
    }
}