// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorTokenBase.sol";

abstract contract CreatorTokenBaseDefault is CreatorTokenBase {
    
    error CreatorTokenBaseDefault__ValidatorMustBeSet();

    address private constant DEFAULT_TRANSFER_VALIDATOR = address(0xCf7BD1590d27a2aAb3BA311BaB424Fd303Cb7f73);
    TransferSecurityLevels private constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.One;
    uint120 private constant DEFAULT_OPERATOR_WHITELIST_ID = uint120(1);

    constructor() 
    CreatorTokenBase(DEFAULT_TRANSFER_VALIDATOR) {}

    function initializeDefaultSecurityPolicy() public virtual onlyOwner {
        ICreatorTokenTransferValidator validator = getTransferValidator();

        if (address(validator) == address(0)) {
            revert CreatorTokenBaseDefault__ValidatorMustBeSet();
        }

        validator.setTransferSecurityLevelOfCollection(address(this), DEFAULT_TRANSFER_SECURITY_LEVEL);
        validator.setOperatorWhitelistOfCollection(address(this), DEFAULT_OPERATOR_WHITELIST_ID);
    }
}
