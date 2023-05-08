// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EOARegistry.sol";
import "../interfaces/IOwnable.sol";
import "../interfaces/ICreatorTokenTransferValidator.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title  CreatorTokenTransferValidator
 * @author Limit Break, Inc.
 * @notice The CreatorTokenTransferValidator contract is designed to provide a customizable and secure transfer 
 *         validation mechanism for NFT collections. This contract allows the owner of an NFT collection to configure 
 *         the transfer security level, operator whitelist, and permitted contract receiver allowlist for each 
 *         collection.
 *
 * @dev    <h4>Features</h4>
 *         - Transfer security levels: Provides different levels of transfer security, 
 *           from open transfers to completely restricted transfers.
 *         - Operator whitelist: Allows the owner of a collection to whitelist specific operator addresses permitted
 *           to execute transfers on behalf of others.
 *         - Permitted contract receiver allowlist: Enables the owner of a collection to allow specific contract 
 *           addresses to receive NFTs when otherwise disabled by security policy.
 *
 * @dev    <h4>Benefits</h4>
 *         - Enhanced security: Allows creators to have more control over their NFT collections, ensuring the safety 
 *           and integrity of their assets.
 *         - Flexibility: Provides collection owners the ability to customize transfer rules as per their requirements.
 *         - Compliance: Facilitates compliance with regulations by enabling creators to restrict transfers based on 
 *           specific criteria.
 *
 * @dev    <h4>Intended Usage</h4>
 *         - The CreatorTokenTransferValidator contract is intended to be used by NFT collection owners to manage and 
 *           enforce transfer policies. This contract is integrated with the following varations of creator token 
 *           NFT contracts to validate transfers according to the defined security policies.
 *
 *           - ERC721-C:   Creator token implenting OpenZeppelin's ERC-721 standard.
 *           - ERC721-AC:  Creator token implenting Azuki's ERC-721A standard.
 *           - ERC721-CW:  Creator token implementing OpenZeppelin's ERC-721 standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-721 collection.
 *           - ERC721-ACW: Creator token implementing Azuki's ERC721-A standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-721 collection.
 *           - ERC1155-C:  Creator token implenting OpenZeppelin's ERC-1155 standard.
 *           - ERC1155-CW: Creator token implementing OpenZeppelin's ERC-1155 standard with opt-in staking to 
 *                         wrap/upgrade a pre-existing ERC-1155 collection.
 *
 *          <h4>Transfer Security Levels</h4>
 *          - Level 0 (Zero): No transfer restrictions.
 *            - Caller Constraints: None
 *            - Receiver Constraints: None
 *          - Level 1 (One): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled.
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: None
 *          - Level 2 (Two): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled.
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: None
 *          - Level 3 (Three): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled. Transfers to contracts with code are not allowed.
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: NoCode
 *          - Level 4 (Four): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading enabled. Transfers are allowed only to Externally Owned Accounts (EOAs).
 *            - Caller Constraints: OperatorWhitelistEnableOTC
 *            - Receiver Constraints: EOA
 *          - Level 5 (Five): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled. Transfers to contracts with code are not allowed.
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: NoCode
 *          - Level 6 (Six): Only whitelisted operators can initiate transfers, with over-the-counter (OTC) trading disabled. Transfers are allowed only to Externally Owned Accounts (EOAs).
 *            - Caller Constraints: OperatorWhitelistDisableOTC
 *            - Receiver Constraints: EOA
 */
contract CreatorTokenTransferValidator is EOARegistry, ICreatorTokenTransferValidator {
    using EnumerableSet for EnumerableSet.AddressSet;

    error CreatorTokenTransferValidator__AddressAlreadyAllowed();
    error CreatorTokenTransferValidator__AddressNotAllowed();
    error CreatorTokenTransferValidator__AllowlistDoesNotExist();
    error CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
    error CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
    error CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
    error CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
    error CreatorTokenTransferValidator__ReceiverMustNotHaveDeployedCode();
    error CreatorTokenTransferValidator__ReceiverProofOfEOASignatureUnverified();
    
    bytes32 private constant DEFAULT_ACCESS_CONTROL_ADMIN_ROLE = 0x00;
    TransferSecurityLevels public constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.Zero;

    uint120 private lastOperatorWhitelistId;
    uint120 private lastPermittedContractReceiverAllowlistId;

    mapping (TransferSecurityLevels => TransferSecurityPolicy) public transferSecurityPolicies;
    mapping (address => CollectionSecurityPolicy) private collectionSecurityPolicies;
    mapping (uint120 => address) public operatorWhitelistOwners;
    mapping (uint120 => address) public permittedContractReceiverAllowlistOwners;
    mapping (uint120 => EnumerableSet.AddressSet) private operatorWhitelists;
    mapping (uint120 => EnumerableSet.AddressSet) private permittedContractReceiverAllowlists;

    constructor(address defaultOwner) EOARegistry() {
        transferSecurityPolicies[TransferSecurityLevels.Zero] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.None,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.One] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.Two] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.None
        });

        transferSecurityPolicies[TransferSecurityLevels.Three] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.NoCode
        });

        transferSecurityPolicies[TransferSecurityLevels.Four] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistEnableOTC,
            receiverConstraints: ReceiverConstraints.EOA
        });

        transferSecurityPolicies[TransferSecurityLevels.Five] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.NoCode
        });

        transferSecurityPolicies[TransferSecurityLevels.Six] = TransferSecurityPolicy({
            callerConstraints: CallerConstraints.OperatorWhitelistDisableOTC,
            receiverConstraints: ReceiverConstraints.EOA
        });

        uint120 id = ++lastOperatorWhitelistId;

        operatorWhitelistOwners[id] = defaultOwner;

        emit CreatedAllowlist(AllowlistTypes.Operators, id, "DEFAULT OPERATOR WHITELIST");
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, defaultOwner);
    }

    /**
     * @notice Apply the collection transfer policy to a transfer operation of a creator token.
     *
     * @dev Throws when the receiver has deployed code but is not in the permitted contract receiver allowlist,
     *      if the ReceiverConstraints is set to NoCode.
     * @dev Throws when the receiver has never verified a signature to prove they are an EOA and the receiver
     *      is not in the permitted contract receiver allowlist, if the ReceiverConstraints is set to EOA.
     * @dev Throws when `msg.sender` is not a whitelisted operator, if CallerConstraints is OperatorWhitelistDisableOTC.
     * @dev Throws when `msg.sender` is neither a whitelisted operator nor the 'from' addresses,
     *      if CallerConstraints is OperatorWhitelistEnableOTC.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. Transfer is allowed or denied based on the applied transfer policy.
     *
     * @param caller The address initiating the transfer.
     * @param from   The address of the token owner.
     * @param to     The address of the token receiver.
     */
    function applyCollectionTransferPolicy(address caller, address from, address to) external view override {
        address collection = _msgSender();
        CollectionSecurityPolicy memory collectionSecurityPolicy = collectionSecurityPolicies[collection];
        TransferSecurityPolicy memory transferSecurityPolicy = 
            transferSecurityPolicies[collectionSecurityPolicy.transferSecurityLevel];
        
        if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.NoCode) {
            if (to.code.length > 0) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert CreatorTokenTransferValidator__ReceiverMustNotHaveDeployedCode();
                }
            }
        } else if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.EOA) {
            if (!isVerifiedEOA(to)) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert CreatorTokenTransferValidator__ReceiverProofOfEOASignatureUnverified();
                }
            }
        }

        if (transferSecurityPolicy.callerConstraints != CallerConstraints.None) {
            if(operatorWhitelists[collectionSecurityPolicy.operatorWhitelistId].length() > 0) {
                if (!isOperatorWhitelisted(collectionSecurityPolicy.operatorWhitelistId, caller)) {
                    if (transferSecurityPolicy.callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC) {
                        if (caller != from) {
                            revert CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
                        }
                    } else {
                        revert CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator();
                    }
                }
            }
        }
    }

    /**
     * @notice Create a new operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. A new operator whitelist with the specified name is created.
     *      2. The caller is set as the owner of the new operator whitelist.
     *      3. A `CreatedAllowlist` event is emitted.
     *      4. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param name The name of the new operator whitelist.
     * @return     The id of the new operator whitelist.
     */
    function createOperatorWhitelist(string calldata name) external override returns (uint120) {
        uint120 id = ++lastOperatorWhitelistId;

        operatorWhitelistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.Operators, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, _msgSender());

        return id;
    }

    /**
     * @notice Create a new permitted contract receiver allowlist.
     * 
     * @dev <h4>Postconditions:</h4>
     *      1. A new permitted contract receiver allowlist with the specified name is created.
     *      2. The caller is set as the owner of the new permitted contract receiver allowlist.
     *      3. A `CreatedAllowlist` event is emitted.
     *      4. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param name The name of the new permitted contract receiver allowlist.
     * @return     The id of the new permitted contract receiver allowlist.
     */
    function createPermittedContractReceiverAllowlist(string calldata name) external override returns (uint120) {
        uint120 id = ++lastPermittedContractReceiverAllowlistId;

        permittedContractReceiverAllowlistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.PermittedContractReceivers, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, id, _msgSender());

        return id;
    }

    /**
     * @notice Transfer ownership of an operator whitelist to a new owner.
     *
     * @dev Throws when the new owner is the zero address.
     * @dev Throws when the caller does not own the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator whitelist ownership is transferred to the new owner.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param newOwner The address of the new owner.
     */
    function reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfOperatorWhitelist(id, newOwner);
    }

    /**
     * @notice Transfer ownership of a permitted contract receiver allowlist to a new owner.
     *
     * @dev Throws when the new owner is the zero address.
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The permitted contract receiver allowlist ownership is transferred to the new owner.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id       The id of the permitted contract receiver allowlist.
     * @param newOwner The address of the new owner.
     */
    function reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, newOwner);
    }

    /**
     * @notice Renounce the ownership of an operator whitelist, rendering the whitelist immutable.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The ownership of the specified operator whitelist is renounced.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id The id of the operator whitelist.
     */
    function renounceOwnershipOfOperatorWhitelist(uint120 id) external override {
        _reassignOwnershipOfOperatorWhitelist(id, address(0));
    }

    /**
     * @notice Renounce the ownership of a permitted contract receiver allowlist, rendering the allowlist immutable.
     *
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The ownership of the specified permitted contract receiver allowlist is renounced.
     *      2. A `ReassignedAllowlistOwnership` event is emitted.
     *
     * @param id The id of the permitted contract receiver allowlist.
     */
    function renounceOwnershipOfPermittedContractReceiverAllowlist(uint120 id) external override {
        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, address(0));
    }

    /**
     * @notice Set the transfer security level of a collection.
     *
     * @dev Throws when the caller is neither collection contract, nor the owner or admin of the specified collection.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The transfer security level of the specified collection is set to the new value.
     *      2. A `SetTransferSecurityLevel` event is emitted.
     *
     * @param collection The address of the collection.
     * @param level      The new transfer security level to apply.
     */
    function setTransferSecurityLevelOfCollection(
        address collection, 
        TransferSecurityLevels level) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);
        collectionSecurityPolicies[collection].transferSecurityLevel = level;
        emit SetTransferSecurityLevel(collection, level);
    }

    /**
     * @notice Set the operator whitelist of a collection.
     * 
     * @dev Throws when the caller is neither collection contract, nor the owner or admin of the specified collection.
     * @dev Throws when the specified operator whitelist id does not exist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator whitelist of the specified collection is set to the new value.
     *      2. A `SetAllowlist` event is emitted.
     *
     * @param collection The address of the collection.
     * @param id         The id of the operator whitelist.
     */
    function setOperatorWhitelistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);

        if (id > lastOperatorWhitelistId) {
            revert CreatorTokenTransferValidator__AllowlistDoesNotExist();
        }

        collectionSecurityPolicies[collection].operatorWhitelistId = id;
        emit SetAllowlist(AllowlistTypes.Operators, collection, id);
    }

    /**
     * @notice Set the permitted contract receiver allowlist of a collection.
     *
     * @dev Throws when the caller does not own the specified collection.
     * @dev Throws when the specified permitted contract receiver allowlist id does not exist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The permitted contract receiver allowlist of the specified collection is set to the new value.
     *      2. A `PermittedContractReceiverAllowlistSet` event is emitted.
     *
     * @param collection The address of the collection.
     * @param id         The id of the permitted contract receiver allowlist.
     */
    function setPermittedContractReceiverAllowlistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);

        if (id > lastPermittedContractReceiverAllowlistId) {
            revert CreatorTokenTransferValidator__AllowlistDoesNotExist();
        }

        collectionSecurityPolicies[collection].permittedContractReceiversId = id;
        emit SetAllowlist(AllowlistTypes.PermittedContractReceivers, collection, id);
    }

    /**
     * @notice Add an operator to an operator whitelist.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     * @dev Throws when the operator address is already allowed.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator is added to the specified operator whitelist.
     *      2. An `AddedToAllowlist` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to add.
     */
    function addOperatorToWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].add(operator)) {
            revert CreatorTokenTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.Operators, id, operator);
    }

    /**
     * @notice Add a contract address to a permitted contract receiver allowlist.
     *
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     * @dev Throws when the contract address is already allowed.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The contract address is added to the specified permitted contract receiver allowlist.
     *      2. An `AddedToAllowlist` event is emitted.
     *
     * @param id              The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to add.
     */
    function addPermittedContractReceiverToAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].add(receiver)) {
            revert CreatorTokenTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    /**
     * @notice Remove an operator from an operator whitelist.
     *
     * @dev Throws when the caller does not own the specified operator whitelist.
     * @dev Throws when the operator is not in the specified operator whitelist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The operator is removed from the specified operator whitelist.
     *      2. A `RemovedFromAllowlist` event is emitted.
     *
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to remove.
     */
    function removeOperatorFromWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].remove(operator)) {
            revert CreatorTokenTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.Operators, id, operator);
    }

    /**
     * @notice Remove a contract address from a permitted contract receiver allowlist.
     * 
     * @dev Throws when the caller does not own the specified permitted contract receiver allowlist.
     * @dev Throws when the contract address is not in the specified permitted contract receiver allowlist.
     *
     * @dev <h4>Postconditions:</h4>
     *      1. The contract address is removed from the specified permitted contract receiver allowlist.
     *      2. A `RemovedFromAllowlist` event is emitted.
     *
     * @param id       The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to remove.
     */
    function removePermittedContractReceiverFromAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].remove(receiver)) {
            revert CreatorTokenTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    /**
     * @notice Get the security policy of the specified collection.
     * @param collection The address of the collection.
     * @return           The security policy of the specified collection, which includes:
     *                   Transfer security level, operator whitelist id, permitted contract receiver allowlist id
     */
    function getCollectionSecurityPolicy(address collection) 
        external view override returns (CollectionSecurityPolicy memory) {
        return collectionSecurityPolicies[collection];
    }

    /**
     * @notice Get the whitelisted operators in an operator whitelist.
     * @param id The id of the operator whitelist.
     * @return   An array of whitelisted operator addresses.
     */
    function getWhitelistedOperators(uint120 id) external view override returns (address[] memory) {
        return operatorWhitelists[id].values();
    }

    /**
     * @notice Get the permitted contract receivers in a permitted contract receiver allowlist.
     * @param id The id of the permitted contract receiver allowlist.
     * @return   An array of contract addresses is the permitted contract receiver allowlist.
     */
    function getPermittedContractReceivers(uint120 id) external view override returns (address[] memory) {
        return permittedContractReceiverAllowlists[id].values();
    }

    /**
     * @notice Check if an operator is in a specified operator whitelist.
     * @param id       The id of the operator whitelist.
     * @param operator The address of the operator to check.
     * @return         True if the operator is in the specified operator whitelist, false otherwise.
     */
    function isOperatorWhitelisted(uint120 id, address operator) public view override returns (bool) {
        return operatorWhitelists[id].contains(operator);
    }

    /**
     * @notice Check if a contract address is in a specified permitted contract receiver allowlist.
     * @param id       The id of the permitted contract receiver allowlist.
     * @param receiver The address of the contract to check.
     * @return         True if the contract address is in the specified permitted contract receiver allowlist, 
     *                 false otherwise.
     */
    function isContractReceiverPermitted(uint120 id, address receiver) public view override returns (bool) {
        return permittedContractReceiverAllowlists[id].contains(receiver);
    }

    /// @notice ERC-165 Interface Support
    function supportsInterface(bytes4 interfaceId) public view virtual override(EOARegistry, IERC165) returns (bool) {
        return
            interfaceId == type(ITransferValidator).interfaceId ||
            interfaceId == type(ITransferSecurityRegistry).interfaceId ||
            interfaceId == type(ICreatorTokenTransferValidator).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _requireCallerIsNFTOrContractOwnerOrAdmin(address tokenAddress) internal view {
        bool callerHasPermissions = false;
        if(tokenAddress.code.length > 0) {
            callerHasPermissions = _msgSender() == tokenAddress;
            if(!callerHasPermissions) {

                try IOwnable(tokenAddress).owner() returns (address contractOwner) {
                    callerHasPermissions = _msgSender() == contractOwner;
                } catch {}

                if(!callerHasPermissions) {
                    try IAccessControl(tokenAddress).hasRole(DEFAULT_ACCESS_CONTROL_ADMIN_ROLE, _msgSender()) 
                        returns (bool callerIsContractAdmin) {
                        callerHasPermissions = callerIsContractAdmin;
                    } catch {}
                }
            }
        }

        if(!callerHasPermissions) {
            revert CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
        }
    }

    function _reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) private {
        _requireCallerOwnsOperatorWhitelist(id);
        operatorWhitelistOwners[id] = newOwner;
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, newOwner);
    }

    function _reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) private {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);
        permittedContractReceiverAllowlistOwners[id] = newOwner;
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, id, newOwner);
    }

    function _requireCallerOwnsOperatorWhitelist(uint120 id) private view {
        if (_msgSender() != operatorWhitelistOwners[id]) {
            revert CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }

    function _requireCallerOwnsPermittedContractReceiverAllowlist(uint120 id) private view {
        if (_msgSender() != permittedContractReceiverAllowlistOwners[id]) {
            revert CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }
}