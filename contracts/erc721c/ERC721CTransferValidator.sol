// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IOwnable.sol";
import "./ITransferSecurityRegistry.sol";
import "./ITransferValidator.sol";
import "../utils/EOARegistry.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract ERC721CTransferValidator is EOARegistry, ITransferValidator, ITransferSecurityRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    error ERC721CTransferValidator__AddressAlreadyAllowed();
    error ERC721CTransferValidator__AddressNotAllowed();
    error ERC721CTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
    error ERC721CTransferValidator__CallerDoesNotOwnAllowlist();
    error ERC721CTransferValidator__CallerMustBeWhitelistedOperator();
    error ERC721CTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
    error ERC721CTransferValidator__ReceiverMustNotHaveDeployedCode();
    error ERC721CTransferValidator__ReceiverProofOfEOASignatureUnverified();
    
    bytes32 private constant DEFAULT_ACCESS_CONTROL_ADMIN_ROLE = 0x00;
    TransferSecurityLevels public constant DEFAULT_TRANSFER_SECURITY_LEVEL = TransferSecurityLevels.Zero;

    uint120 private lastOperatorWhitelistId;
    uint120 private lastPermittedContractReceiverAllowlistId;

    mapping (TransferSecurityLevels => TransferSecurityPolicy) public transferSecurityPolicies;
    mapping (address => CollectionSecurityPolicy) private collectionSecurityPolicies;
    mapping (uint120 => address) private operatorWhitelistOwners;
    mapping (uint120 => address) private permittedContractReceiverAllowlistOwners;
    mapping (uint120 => EnumerableSet.AddressSet) private operatorWhitelists;
    mapping (uint120 => EnumerableSet.AddressSet) private permittedContractReceiverAllowlists;

    constructor() EOARegistry() {
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
    }

    function applyCollectionTransferPolicy(address caller, address from, address to) external view override {
        address collection = _msgSender();
        CollectionSecurityPolicy memory collectionSecurityPolicy = collectionSecurityPolicies[collection];
        TransferSecurityPolicy memory transferSecurityPolicy = 
            transferSecurityPolicies[collectionSecurityPolicy.transferSecurityLevel];
        
        if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.NoCode) {
            if (to.code.length > 0) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert ERC721CTransferValidator__ReceiverMustNotHaveDeployedCode();
                }
            }
        } else if (transferSecurityPolicy.receiverConstraints == ReceiverConstraints.EOA) {
            if (!isVerifiedEOA(to)) {
                if (!isContractReceiverPermitted(collectionSecurityPolicy.permittedContractReceiversId, to)) {
                    revert ERC721CTransferValidator__ReceiverProofOfEOASignatureUnverified();
                }
            }
        }

        if (transferSecurityPolicy.callerConstraints != CallerConstraints.None) {
            if (!isOperatorWhitelisted(collectionSecurityPolicy.operatorWhitelistId, caller)) {
                if (transferSecurityPolicy.callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC) {
                    if (caller != from) {
                        revert ERC721CTransferValidator__CallerMustBeWhitelistedOperator();
                    }
                } else {
                    revert ERC721CTransferValidator__CallerMustBeWhitelistedOperator();
                }
            }
        }
    }

    function createOperatorWhitelist(string calldata name) external override returns (uint120) {
        uint120 id = ++lastOperatorWhitelistId;

        operatorWhitelistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.Operators, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, id, _msgSender());

        return id;
    }

    function createPermittedContractReceiverAllowlists(string calldata name) external override returns (uint120) {
        uint120 id = ++lastPermittedContractReceiverAllowlistId;

        permittedContractReceiverAllowlistOwners[id] = _msgSender();

        emit CreatedAllowlist(AllowlistTypes.PermittedContractReceivers, id, name);
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, id, _msgSender());

        return id;
    }

    function reassignOwnershipOfOperatorWhitelist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert ERC721CTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfOperatorWhitelist(id, newOwner);
    }

    function reassignOwnershipOfPermittedContractReceiverAllowlist(uint120 id, address newOwner) external override {
        if(newOwner == address(0)) {
            revert ERC721CTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress();
        }

        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, newOwner);
    }

    function renounceOwnershipOfOperatorWhitelist(uint120 id) external override {
        _reassignOwnershipOfOperatorWhitelist(id, address(0));
    }

    function renounceOwnershipOfPermittedContractReceiverAllowlist(uint120 id) external override {
        _reassignOwnershipOfPermittedContractReceiverAllowlist(id, address(0));
    }

    function setTransferSecurityLevelOfCollection(
        address collection, 
        TransferSecurityLevels level) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);
        collectionSecurityPolicies[collection].transferSecurityLevel = level;
        emit SetTransferSecurityLevel(collection, level);
    }

    function setOperatorWhitelistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);
        collectionSecurityPolicies[collection].operatorWhitelistId = id;
        emit SetAllowlist(AllowlistTypes.Operators, collection, id);
    }

    function setPermittedContractReceiverAllowlistOfCollection(address collection, uint120 id) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(collection);
        collectionSecurityPolicies[collection].permittedContractReceiversId = id;
        emit SetAllowlist(AllowlistTypes.PermittedContractReceivers, collection, id);
    }

    function addOperatorToWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].add(operator)) {
            revert ERC721CTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.Operators, id, operator);
    }

    function addPermittedContractReceiverToAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].add(receiver)) {
            revert ERC721CTransferValidator__AddressAlreadyAllowed();
        }

        emit AddedToAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    function removeOperatorFromWhitelist(uint120 id, address operator) external override {
        _requireCallerOwnsOperatorWhitelist(id);

        if (!operatorWhitelists[id].remove(operator)) {
            revert ERC721CTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.Operators, id, operator);
    }

    function removePermittedContractReceiverFromAllowlist(uint120 id, address receiver) external override {
        _requireCallerOwnsPermittedContractReceiverAllowlist(id);

        if (!permittedContractReceiverAllowlists[id].remove(receiver)) {
            revert ERC721CTransferValidator__AddressNotAllowed();
        }

        emit RemovedFromAllowlist(AllowlistTypes.PermittedContractReceivers, id, receiver);
    }

    function getCollectionSecurityPolicy(address collection) 
        external view override returns (CollectionSecurityPolicy memory) {
        return collectionSecurityPolicies[collection];
    }

    function getWhitelistedOperators(uint120 id) external view override returns (address[] memory) {
        return operatorWhitelists[id].values();
    }

    function getPermittedContractReceivers(uint120 id) external view override returns (address[] memory) {
        return permittedContractReceiverAllowlists[id].values();
    }

    function isOperatorWhitelisted(uint120 id, address operator) public view override returns (bool) {
        return operatorWhitelists[id].contains(operator);
    }

    function isContractReceiverPermitted(uint120 id, address receiver) public view override returns (bool) {
        return permittedContractReceiverAllowlists[id].contains(receiver);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITransferValidator).interfaceId ||
            interfaceId == type(ITransferSecurityRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _requireCallerIsNFTOrContractOwnerOrAdmin(address tokenAddress) internal view {
        bool callerHasPermissions = false;
        if(tokenAddress.code.length > 0) {
            callerHasPermissions = _msgSender() == tokenAddress;
            if(!callerHasPermissions) {
                try IOwnable(tokenAddress).owner() returns (address contractOwner) {
                    callerHasPermissions = _msgSender() == contractOwner;
                } catch {
                    try IAccessControl(tokenAddress).hasRole(DEFAULT_ACCESS_CONTROL_ADMIN_ROLE, _msgSender()) 
                        returns (bool callerIsContractAdmin) {
                        callerHasPermissions = callerIsContractAdmin;
                    } catch {}
                }
            }
        }

        if(!callerHasPermissions) {
            revert ERC721CTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
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
            revert ERC721CTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }

    function _requireCallerOwnsPermittedContractReceiverAllowlist(uint120 id) private view {
        if (_msgSender() != permittedContractReceiverAllowlistOwners[id]) {
            revert ERC721CTransferValidator__CallerDoesNotOwnAllowlist();
        }
    }
}