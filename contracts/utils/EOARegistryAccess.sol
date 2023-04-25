// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IEOARegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title EOARegistryAccess
 * @author Limit Break, Inc.
 * @notice A contract mixin that provides access to an external EOA registry.
 * For use when a contract needs the ability to check if an address is a verified EOA.
 * @dev Take care and carefully consider whether or not to use this. Restricting operations to EOA only accounts can break Defi composability, 
 * so if Defi composability is an objective, this is not a good option.  Be advised that in the future, EOA accounts might not be a thing
 * but this is yet to be determined.  See https://eips.ethereum.org/EIPS/eip-4337 for more information.
 */
abstract contract EOARegistryAccess is Ownable {
    
    error InvalidEOARegistryContract();
    
    /// @dev Points to an external contract that implements the `IEOARegistry` interface.
    IEOARegistry private eoaRegistry;

    /// @dev Emitted whenever the contract owner changes the EOA registry
    event EOARegistryUpdated(address oldRegistry, address newRegistry);

    /// @notice Allows contract owner to set the pointer to the EOA registry.
    ///
    /// Throws when the specified address in non-zero and does not implement `IEOARegistry`.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// The eoa registry address is set to the specified address.
    /// An `EOARegistryUpdated` event has been emitted.
    function setEOARegistry(address eoaRegistry_) public onlyOwner {
        bool isValidEOARegistry = false;

        if(eoaRegistry_.code.length > 0) {
            try IERC165(eoaRegistry_).supportsInterface(type(IEOARegistry).interfaceId) returns (bool supportsInterface) {
                isValidEOARegistry = supportsInterface;
            } catch {}
        }

        if(eoaRegistry_ != address(0) && !isValidEOARegistry) {
            revert InvalidEOARegistryContract();
        }

        emit EOARegistryUpdated(address(eoaRegistry), eoaRegistry_);

        eoaRegistry = IEOARegistry(eoaRegistry_);
    }

    /// @notice Returns the address of the EOA registry.
    function getEOARegistry() public view returns (IEOARegistry) {
        return eoaRegistry;
    }
}
