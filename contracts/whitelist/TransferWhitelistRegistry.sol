// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ITransferWhitelist.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error ExchangeIsWhitelisted();
error ExchangeIsNotWhitelisted();

/**
 * @title TransferWhitelistRegistry
 * @author Limit Break, Inc.
 * @notice A simple implementation of a transfer whitelist registry contract.
 * It is highly recommended that the initial contract owner transfers ownership 
 * of this contract to a multi-sig wallet.  The multi-sig may be controlled by
 * the project's preferred governance structure.
 */
contract TransferWhitelistRegistry is ERC165, Ownable, ITransferWhitelist {

    /// @dev Tracks the number of whitelisted exchanges
    uint256 private whitelistedExchangeCount;

    /// @dev Mapping of whitelisted exchange addresses
    mapping (address => bool) private exchangeWhitelist;

    /// @dev Emitted when an address is added to the whitelist
    event ExchangeAddedToWhitelist(address indexed exchange);

    /// @dev Emitted when an address is removed from the whitelist
    event ExchangeRemovedFromWhitelist(address indexed exchange);

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(ITransferWhitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Allows contract owner to whitelist an address.
    /// 
    /// Throws when the specified address is already whitelisted.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// Whitelisted exchange count is incremented by 1.
    /// Specified address is now whitelisted.
    /// An `ExchangeAddedToWhitelist` event has been emitted.
    function whitelistExchange(address account) external onlyOwner {
        if(exchangeWhitelist[account]) {
            revert ExchangeIsWhitelisted();
        }

        ++whitelistedExchangeCount;
        exchangeWhitelist[account] = true;
        emit ExchangeAddedToWhitelist(account);
    }

    /// @notice Allows contract owner to remove an address from the whitelist.
    /// 
    /// Throws when the specified address is not whitelisted.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// Whitelisted exchange count is decremented by 1.
    /// Specified address is no longer whitelisted.
    /// An `ExchangeRemovedFromWhitelist` event has been emitted.
    function unwhitelistExchange(address account) external onlyOwner {
        if(!exchangeWhitelist[account]) {
            revert ExchangeIsNotWhitelisted();
        }

        unchecked {
            --whitelistedExchangeCount;
        }

        delete exchangeWhitelist[account];
        emit ExchangeRemovedFromWhitelist(account);
    }

    /// @notice Returns the number of exchanges that are currently in the whitelist
    function getWhitelistedExchangeCount() external view override returns (uint256) {
        return whitelistedExchangeCount;
    }

    /// @notice Returns true if the specified account is in the whitelist, false otherwise
    function isWhitelistedExchange(address account) external view override returns (bool) {
        return exchangeWhitelist[account];
    }

    /// @notice Returns true if the caller is permitted to execute a transfer, false otherwise.
    /// @dev Transfers are unrestricted if the whitelist is empty.
    function isTransferWhitelisted(address caller) external view override returns (bool) {
        return 
        (whitelistedExchangeCount == 0) ||
        (exchangeWhitelist[caller]);
    }

    
}