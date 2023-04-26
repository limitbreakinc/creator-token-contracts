// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "../mocks/ERC721CMock.sol";
import "../helpers/DeploysCreatorTokenTransferValidator.sol";
import "contracts/utils/TransferPolicy.sol";

contract ERC721CTestBase is 
    DeploysCreatorTokenTransferValidator {

    ERC721CMock private token;

    function setUp() public {
        deployTransferValidator();

        token = new ERC721CMock();
        token.initializeDefaultSecurityPolicy();
    }

    function testDefaultValidator() public {
        assertEq(address(token.getTransferValidator()), address(validator));
    }

    function testDefaultTransferSecurityLevel() public {
        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertEq(uint8(securityPolicy.transferSecurityLevel), uint8(TransferSecurityLevels.One));
    }

    function testDefaultOperatorWhitelistId() public {
        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertEq(securityPolicy.operatorWhitelistId, 1);
    }

    function testDeterministicAddressForCreatorTokenValidator() public {
        assertEq(address(validator), 0xCf7BD1590d27a2aAb3BA311BaB424Fd303Cb7f73);
    }
}