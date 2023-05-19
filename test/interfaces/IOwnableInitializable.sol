// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IOwnableInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin Ownable functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IOwnableInitializer is IERC165 {
    /**
     * @notice Initializes the contract owner to the specified address
     */
    function initializeOwner(address owner_) external;

    /**
     * @notice Transfers ownership of the contract to the specified owner
     */
    function transferOwnership(address newOwner) external;
}
