// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IEOARegistry
 * @author Limit Break, Inc.
 * @notice Interface for a registry of verified EOA accounts.
 */
interface IEOARegistry is IERC165 {

    /// @dev Returns true if the account has been verified as an EOA, false otherwise
    function isVerifiedEOA(address account) external view returns (bool);
}