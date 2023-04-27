// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorTokenBase.sol";

abstract contract CreatorTokenBaseDefault is CreatorTokenBase {

    address private constant DEFAULT_TRANSFER_VALIDATOR = address(0xBc894CF84D8f03c23B3e8182F8d5A34013A147Ab);
    TransferSecurityLevels private constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.One;
    uint120 private constant DEFAULT_OPERATOR_WHITELIST_ID = uint120(1);

    function initializeDefaultSecurityPolicy() public virtual onlyOwner {
        setTransferValidator(DEFAULT_TRANSFER_VALIDATOR);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setTransferSecurityLevelOfCollection(address(this), DEFAULT_TRANSFER_SECURITY_LEVEL);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setOperatorWhitelistOfCollection(address(this), DEFAULT_OPERATOR_WHITELIST_ID);
    }
}
