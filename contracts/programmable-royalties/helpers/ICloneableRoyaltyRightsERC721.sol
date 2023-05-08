// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICloneableRoyaltyRightsERC721 is IERC721 {
    function initializeAndBindToCollection() external;
    function mint(address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}
