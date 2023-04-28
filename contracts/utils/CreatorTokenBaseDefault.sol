// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorTokenBase.sol";

abstract contract CreatorTokenBaseDefault is CreatorTokenBase {

    address public constant DEFAULT_TRANSFER_VALIDATOR = address(0xBc894CF84D8f03c23B3e8182F8d5A34013A147Ab);
    TransferSecurityLevels public constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.One;
    uint120 public constant DEFAULT_OPERATOR_WHITELIST_ID = uint120(1);

    function setToDefaultSecurityPolicy() public virtual onlyOwner {
        setTransferValidator(DEFAULT_TRANSFER_VALIDATOR);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setTransferSecurityLevelOfCollection(address(this), DEFAULT_TRANSFER_SECURITY_LEVEL);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setOperatorWhitelistOfCollection(address(this), DEFAULT_OPERATOR_WHITELIST_ID);
    }

    function setToCustomSecurityPolicy(
        address validator, 
        TransferSecurityLevels level, 
        uint120 operatorWhitelistId, 
        uint120 permittedContractReceiversAllowlistId) public virtual onlyOwner {
        setTransferValidator(validator);

        ICreatorTokenTransferValidator(validator).
            setTransferSecurityLevelOfCollection(address(this), level);

        ICreatorTokenTransferValidator(validator).
            setOperatorWhitelistOfCollection(address(this), operatorWhitelistId);
            
        ICreatorTokenTransferValidator(validator).
            setPermittedContractReceiverAllowlistOfCollection(address(this), permittedContractReceiversAllowlistId);
    }
}
