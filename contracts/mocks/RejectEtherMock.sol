// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract RejectEtherMock {
    receive() external payable {
        revert("Receiving ETH not permitted");
    }    
}