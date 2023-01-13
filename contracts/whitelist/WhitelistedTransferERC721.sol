// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITransferWhitelist.sol";
import "../utils/TransferValidation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title WhitelistedTransferERC721
 * @author Limit Break, Inc.
 * @notice Extends Openzeppelin's ERC721 implementation with transfer validation logic
 * to enforce that transfers can only be initiated by whitelisted callers.
 */
abstract contract WhitelistedTransferERC721 is Ownable, ERC721, TransferValidation {
    
    error CallerIsNotWhitelisted(address caller);
    error InvalidTransferWhitelistContract();

    /// @dev Points to an external contract that implements the `ITransferWhitelist` interface.
    ITransferWhitelist private transferWhitelist;

    /// @dev Emitted whenever the contract owner changes the transfer whitelist registry
    event TransferWhitelistRegistryUpdated(address oldRegistry, address newRegistry);

    /// @notice Allows contract owner to set the pointer to the whitelist registry.
    ///
    /// Throws when the specified address in non-zero and does not implement `ITransferWhitelist`.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// The transfer whitelist address is set to the specified address.
    /// A `TransferWhitelistRegistryUpdated` event has been emitted.
    function setWhitelistRegistry(address whitelistRegistry_) public onlyOwner {
        bool isValidTransferWhitelist = false;

        if(whitelistRegistry_.code.length > 0) {
            try IERC165(whitelistRegistry_).supportsInterface(type(ITransferWhitelist).interfaceId) returns (bool supportsInterface) {
                isValidTransferWhitelist = supportsInterface;
            } catch {}
        }

        if(whitelistRegistry_ != address(0) && !isValidTransferWhitelist) {
            revert InvalidTransferWhitelistContract();
        }

        emit TransferWhitelistRegistryUpdated(address(transferWhitelist), whitelistRegistry_);

        transferWhitelist = ITransferWhitelist(whitelistRegistry_);
    }

    /// @notice Returns the address of the transfer whitelist registry.
    function getTransferWhitelist() public view returns (ITransferWhitelist) {
        return transferWhitelist;
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateBeforeTransfer(from, to, tokenId);
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateAfterTransfer(from, to, tokenId);
    }

    /// @dev Ensures that a transfer that is not a mint or a burn can only be initiated by a whitelisted address.
    ///
    /// Throws when the whitelist registry has been set, there is at least one whitelisted address, and the caller is not in the whitelist.
    function _preValidateTransfer(address caller, address /*from*/, address /*to*/, uint256 /*tokenId*/, uint256 /*value*/) internal virtual override {
        if(address(transferWhitelist) != address(0) && !transferWhitelist.isTransferWhitelisted(caller)) {
            revert CallerIsNotWhitelisted(caller);
        }
    }
}
