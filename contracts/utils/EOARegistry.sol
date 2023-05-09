// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../interfaces/IEOARegistry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


error CallerIsNotEOA();
error EOAAlreadyVerified();

/**
 * @title EOARegistry
 * @author Limit Break, Inc.
 * @notice A registry that may be used globally by any smart contract that limits contract interactions to verified EOA addresses only.
 * @dev Take care and carefully consider whether or not to use this. Restricting operations to EOA only accounts can break Defi composability, 
 * so if Defi composability is an objective, this is not a good option.  Be advised that in the future, EOA accounts might not be a thing
 * but this is yet to be determined.  See https://eips.ethereum.org/EIPS/eip-4337 for more information.
 */
contract EOARegistry is ERC165, IEOARegistry {

    /// @dev Mapping of accounts that to verification status
    mapping (address => bool) private eoaVerified;

    /// @dev Emitted whenever a user verifies that they are an EOA.
    event VerifiedEOA(address indexed account);

    /// @notice Allows a user to verify their account is an EOA
    ///
    /// Throws when the caller has already verified their EOA.
    /// Throws when the caller is not transaction origin
    ///
    /// Postconditions:
    /// ---------------
    /// The verified EOA mapping has been updated to `true` for the caller.
    function verify() external {
        if(eoaVerified[msg.sender]) {
            revert EOAAlreadyVerified();
        }

        if(msg.sender != tx.origin) {
            revert CallerIsNotEOA();
        }

        eoaVerified[msg.sender] = true;

        emit VerifiedEOA(msg.sender);
    }

    /// @notice Returns true if the specified account has verified a signature on this registry, false otherwise.
    function isVerifiedEOA(address account) public view override returns (bool) {
        return eoaVerified[account];
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IEOARegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}