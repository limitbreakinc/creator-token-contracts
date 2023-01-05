// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ITransferWhitelist
 * @author Limit Break, Inc.
 * @notice Interface for transfer whitelist registries.
 */
interface ITransferWhitelist is IERC165 {

    /// @dev Returns the number of exchanges that are currently in the whitelist
    function getWhitelistedExchangeCount() external view returns (uint256);

    /// @dev Returns true if the specified account is in the whitelist, false otherwise
    function isWhitelistedExchange(address account) external view returns (bool);

    /// @dev Returns true if the caller is permitted to execute a transfer, false otherwise
    function isTransferWhitelisted(address caller) external view returns (bool);
}