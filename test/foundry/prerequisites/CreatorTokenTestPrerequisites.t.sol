// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";

contract CreatorTokenTestPrerequisites is Test {

    CreatorTokenTransferValidator private validator;
    bytes32 saltValue = bytes32(uint256(8946686101848117716489848979750688532688049124417468924436884748620307827805));

    function setUp() public {
        vm.startPrank(address(0xdeadbeef));
        validator = new CreatorTokenTransferValidator{salt: saltValue}();
        vm.stopPrank();
        console.log("Validator deterministically deployed to ", address(validator));
    }

    function testDeterministicAddressForCreatorTokenValidator() public {
        assertEq(address(validator), 0x88469F1B1b81F2446e0B110e441ADD5ED785BC65);
    }
}