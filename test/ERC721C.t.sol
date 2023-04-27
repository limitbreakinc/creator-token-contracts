// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ERC721CMock.sol";
import "contracts/utils/TransferPolicy.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";

contract ERC721CTest is Test {

    bytes32 private saltValue = bytes32(uint256(8946686101848117716489848979750688532688049124417468924436884748620307827805));
    
    CreatorTokenTransferValidator public validator;
    ERC721CMock public token;

    function setUp() public {
        address deployer = vm.addr(1);
        vm.startPrank(deployer);
        validator = new CreatorTokenTransferValidator{salt: saltValue}();
        vm.stopPrank();
        
        token = new ERC721CMock();
    }

    function testDefaultValidator() public {
        token.initializeDefaultSecurityPolicy();
        assertEq(address(token.getTransferValidator()), address(validator));
    }

    function testDefaultTransferSecurityLevel() public {
        token.initializeDefaultSecurityPolicy();
        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertEq(uint8(securityPolicy.transferSecurityLevel), uint8(TransferSecurityLevels.One));
    }

    function testDefaultOperatorWhitelistId() public {
        token.initializeDefaultSecurityPolicy();
        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertEq(securityPolicy.operatorWhitelistId, 1);
    }

    function testDeterministicAddressForCreatorTokenValidator() public {
        assertEq(address(validator), 0xBc894CF84D8f03c23B3e8182F8d5A34013A147Ab);
    }

    /*
    function testSetTransferValidator() public {
        token.setTransferValidator(address(validator));
    }
    */

    function testIsTransferByOwnerAllowedByDefault(address owner, address to) public {
        vm.assume(owner != address(0));
        token.initializeDefaultSecurityPolicy();
        bool isTransferAllowed = token.isTransferAllowed(owner, owner, to);
        assertEq(isTransferAllowed, true);
    }
}