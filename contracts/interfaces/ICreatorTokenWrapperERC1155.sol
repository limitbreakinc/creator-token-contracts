// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ICreatorToken.sol";

interface ICreatorTokenWrapperERC1155 is ICreatorToken {

    event Staked(uint256 indexed id, address indexed account, uint256 amount);
    event Unstaked(uint256 indexed id, address indexed account, uint256 amount);
    event StakerConstraintsSet(StakerConstraints stakerConstraints);

    function stake(uint256 tokenId, uint256 amount) external payable;
    function unstake(uint256 tokenId, uint256 amount) external payable;
    function canUnstake(uint256 tokenId, uint256 amount) external view returns (bool);
    function getStakerConstraints() external view returns (StakerConstraints);
    function getWrappedCollectionAddress() external view returns (address);
}
