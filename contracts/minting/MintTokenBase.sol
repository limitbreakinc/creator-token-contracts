// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title MintTokenBase
 * @author Limit Break, Inc.
 * @dev Standard mint token interface for mixins to mint tokens.
 */
abstract contract MintTokenBase {
    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use _mint, or something equivalent
    /// The minting function should throw if `to` is address(0)
    function _mintToken(address to, uint256 tokenId) internal virtual;
}