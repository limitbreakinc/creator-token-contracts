// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorTokenBase.sol";

abstract contract CreatorTokenBaseDefault is CreatorTokenBase {
    
    address private constant DEFAULT_TRANSFER_VALIDATOR = address(0x88469F1B1b81F2446e0B110e441ADD5ED785BC65);
    TransferSecurityLevels private constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.One;
    uint120 private constant DEFAULT_OPERATOR_WHITELIST_ID = uint120(1);

    constructor() 
    CreatorTokenBase(DEFAULT_TRANSFER_VALIDATOR) {
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setTransferSecurityLevelOfCollection(
            address(this), 
            DEFAULT_TRANSFER_SECURITY_LEVEL
        );

        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setOperatorWhitelistOfCollection(
            address(this), 
            DEFAULT_OPERATOR_WHITELIST_ID
        );
    }
}
