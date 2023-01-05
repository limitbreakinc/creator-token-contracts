// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICreatorERC721 {
    function stake(uint256 tokenId) external payable;
}

contract MultiSigMock {
    
    constructor() {}

    function execStake(address wrapperNftAddress, uint256 tokenId) external {
        ICreatorERC721(wrapperNftAddress).stake(tokenId);
    }

    function setApprovalForAll(address nftAddress, address operator, bool approved) external {
        IERC721(nftAddress).setApprovalForAll(operator, approved);
    }
}