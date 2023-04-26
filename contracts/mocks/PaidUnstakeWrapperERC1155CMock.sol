// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../erc1155c/presets/ERC1155CWPaidUnstake.sol";

contract PaidUnstakeWrapperERC1155CMock is ERC1155CWPaidUnstake {
    constructor(
        uint256 unrevealPrice_, 
        address wrappedCollectionAddress_, 
        string memory uri_) 
        ERC1155CWPaidUnstake(unrevealPrice_, wrappedCollectionAddress_, uri_) {
        }
}