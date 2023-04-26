// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";

abstract contract DeploysCreatorTokenTransferValidator is Test {

    CreatorTokenTransferValidator public validator;
    bytes32 private saltValue = bytes32(uint256(8946686101848117716489848979750688532688049124417468924436884748620307827805));

    function deployTransferValidator() public virtual {
        address deployer = vm.addr(1);
        vm.prank(deployer);
        validator = new CreatorTokenTransferValidator{salt: saltValue}();
        console.log(address(validator));
    }
}