// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title SafeMintTokenBase
 * @author Limit Break, Inc.
 * @dev Standard safe mint token interface for mixins to call safe mint.
 */
abstract contract SafeMintTokenBase {
    /// @dev Inheriting contracts must implement the token minting logic - inheriting contract should use _safeMint, or something equivalent
    /// The minting function should throw if `to` is address(0) or `to` is a contract that does not implement IERC721Receiver.
    function _safeMintToken(address to, uint256 tokenId) internal virtual;
}