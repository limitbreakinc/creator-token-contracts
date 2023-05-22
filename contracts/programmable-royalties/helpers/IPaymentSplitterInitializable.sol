// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPaymentSplitterInitializable {
    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function totalReleased(IERC20 token) external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function released(address account) external view returns (uint256);
    function released(IERC20 token, address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);
    function releasable(address account) external view returns (uint256);
    function releasable(IERC20 token, address account) external view returns (uint256);
    function initializePaymentSplitter(address[] calldata payees, uint256[] calldata shares_) external;
    function release(address payable account) external;
    function release(IERC20 token, address account) external;
}