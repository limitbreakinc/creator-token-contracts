// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/interfaces/ICreatorToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITestCreatorMintableToken is IERC721, ICreatorToken {
    function mint(address, uint256) external;
    function remainingOwnerMints() external view returns (uint256);
    function ownerMint(address, uint256) external;
    function initializeMaxSupply(uint256, uint256) external;
    function maxSupplyInitialized() external view returns (bool);
    function owner() external view returns (address);
    function maxSupply() external view returns (uint256);
    function openClaims(uint256) external;
    function closeClaims(uint256) external;
    function getClaimPeriodClosingTimestamp() external view returns (uint256);
    function isClaimPeriodOpen() external view returns (bool);
}
