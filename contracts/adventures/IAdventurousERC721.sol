// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAdventurous.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IAdventurousERC721
 * @author Limit Break, Inc.
 * @notice Combines all {IAdventurous} and all {IERC721} functionality into a single, unified interface.
 * @dev This interface may be used as a convenience to interact with tokens that support both interface standards.
 */
interface IAdventurousERC721 is IERC721, IAdventurous {

}