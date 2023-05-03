// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorTokenBase.sol";

/**
 * @title CreatorTokenBaseDefault
 * @author Limit Break, Inc.
 * @notice A helper contract layer that makes it easy to configure creator tokens with 
 *         recommended default transfer validator and security policy settings.
 */
abstract contract CreatorTokenBaseDefault is CreatorTokenBase {

    address public constant DEFAULT_TRANSFER_VALIDATOR = address(0x559567c6B0771750e6bE3052169843f13b2f1654);
    TransferSecurityLevels public constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.One;
    uint120 public constant DEFAULT_OPERATOR_WHITELIST_ID = uint120(1);

    /**
     * @notice Allows the contract owner to set the transfer validator to the official validator contract
     *         and set the security policy to the recommended default settings.
     * @dev    May be overridden to change the default behavior of an individual collection.
     */
    function setToDefaultSecurityPolicy() public virtual onlyOwner {
        setTransferValidator(DEFAULT_TRANSFER_VALIDATOR);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setTransferSecurityLevelOfCollection(address(this), DEFAULT_TRANSFER_SECURITY_LEVEL);
        ICreatorTokenTransferValidator(DEFAULT_TRANSFER_VALIDATOR).setOperatorWhitelistOfCollection(address(this), DEFAULT_OPERATOR_WHITELIST_ID);
    }

    /**
     * @notice Allows the contract owner to set the transfer validator to a custom validator contract
     *         and set the security policy to their own custom settings.
     * @dev    May be overridden to change the behavior in an individual collection.
     */
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
