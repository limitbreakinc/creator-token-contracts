// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ERC721CMock.sol";
import "contracts/utils/TransferPolicy.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";

contract CreatorTokenTransferValidatorTest is Test {

    event AddedToAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event CreatedAllowlist(AllowlistTypes indexed kind, uint256 indexed id, string indexed name);
    event ReassignedAllowlistOwnership(AllowlistTypes indexed kind, uint256 indexed id, address indexed newOwner);
    event RemovedFromAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event SetAllowlist(AllowlistTypes indexed kind, address indexed collection, uint120 indexed id);
    event SetTransferSecurityLevel(address indexed collection, TransferSecurityLevels level);

    bytes32 private saltValue = bytes32(uint256(8946686101848117716489848979750688532688049124417468924436884748620307827805));
    
    CreatorTokenTransferValidator public validator;

    function setUp() public {
        address deployer = vm.addr(1);
        vm.startPrank(deployer);
        validator = new CreatorTokenTransferValidator{salt: saltValue}();
        vm.stopPrank();
        console.log(address(validator));
    }

    function testTransferSecurityLevelZero() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Zero);
        assertEq(uint8(TransferSecurityLevels.Zero), 0);
        assertTrue(callerConstraints == CallerConstraints.None);
        assertTrue(receiverConstraints == ReceiverConstraints.None);
    }

    function testTransferSecurityLevelOne() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.One);
        assertEq(uint8(TransferSecurityLevels.One), 1);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.None);
    }

    function testTransferSecurityLevelTwo() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Two);
        assertEq(uint8(TransferSecurityLevels.Two), 2);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistDisableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.None);
    }

    function testTransferSecurityLevelThree() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Three);
        assertEq(uint8(TransferSecurityLevels.Three), 3);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.NoCode);
    }

    function testTransferSecurityLevelFour() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Four);
        assertEq(uint8(TransferSecurityLevels.Four), 4);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistEnableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.EOA);
    }

    function testTransferSecurityLevelFive() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Five);
        assertEq(uint8(TransferSecurityLevels.Five), 5);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistDisableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.NoCode);
    }

    function testTransferSecurityLevelSix() public {
        (CallerConstraints callerConstraints, ReceiverConstraints receiverConstraints) =  validator.transferSecurityPolicies(TransferSecurityLevels.Six);
        assertEq(uint8(TransferSecurityLevels.Six), 6);
        assertTrue(callerConstraints == CallerConstraints.OperatorWhitelistDisableOTC);
        assertTrue(receiverConstraints == ReceiverConstraints.EOA);
    }

    function testCreateOperatorWhitelist(address listOwner, string memory name) public {
        vm.assume(listOwner != address(0));
        vm.assume(bytes(name).length < 200);

        uint120 firstListId = 2;
        for (uint120 i = 0; i < 5; ++i) {
            uint120 expectedId = firstListId + i;

            vm.expectEmit(true, true, true, false);
            emit CreatedAllowlist(AllowlistTypes.Operators, expectedId, name);

            vm.expectEmit(true, true, true, false);
            emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, expectedId, listOwner);

            vm.prank(listOwner);
            uint120 actualId = validator.createOperatorWhitelist(name);
            assertEq(actualId, expectedId);
            assertEq(validator.operatorWhitelistOwners(actualId), listOwner);
        }
    }

    function testCreatePermittedContractReceiverAllowlist(address listOwner, string memory name) public {
        vm.assume(listOwner != address(0));
        vm.assume(bytes(name).length < 200);

        uint120 firstListId = 1;
        for (uint120 i = 0; i < 5; ++i) {
            uint120 expectedId = firstListId + i;

            vm.expectEmit(true, true, true, false);
            emit CreatedAllowlist(AllowlistTypes.PermittedContractReceivers, expectedId, name);

            vm.expectEmit(true, true, true, false);
            emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, expectedId, listOwner);

            vm.prank(listOwner);
            uint120 actualId = validator.createPermittedContractReceiverAllowlist(name);
            assertEq(actualId, expectedId);
            assertEq(validator.permittedContractReceiverAllowlistOwners(actualId), listOwner);
        }
    }

    function testReassignOwnershipOfOperatorWhitelist(address originalListOwner, address newListOwner) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(newListOwner != address(0));
        vm.assume(originalListOwner != newListOwner);

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectEmit(true, true, true, false);
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, listId, newListOwner);

        vm.prank(originalListOwner);
        validator.reassignOwnershipOfOperatorWhitelist(listId, newListOwner);
        assertEq(validator.operatorWhitelistOwners(listId), newListOwner);
    }

    function testRevertsWhenReassigningOwnershipOfOperatorWhitelistToZero(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress.selector);
        validator.reassignOwnershipOfOperatorWhitelist(listId, address(0));
    }

    function testRevertsWhenNonOwnerReassignsOwnershipOfOperatorWhitelist(address originalListOwner, address unauthorizedUser) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.reassignOwnershipOfOperatorWhitelist(listId, unauthorizedUser);
    }

    function testReassignOwnershipOfPermittedContractReceiversAllowlist(address originalListOwner, address newListOwner) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(newListOwner != address(0));
        vm.assume(originalListOwner != newListOwner);

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectEmit(true, true, true, false);
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, listId, newListOwner);

        vm.prank(originalListOwner);
        validator.reassignOwnershipOfPermittedContractReceiverAllowlist(listId, newListOwner);
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), newListOwner);
    }

    function testRevertsWhenReassigningOwnershipOfPermittedContractReceiversAllowlistToZero(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistOwnershipCannotBeTransferredToZeroAddress.selector);
        validator.reassignOwnershipOfPermittedContractReceiverAllowlist(listId, address(0));
    }

    function testRevertsWhenNonOwnerReassignsOwnershipOfPermittedContractReceiversAllowlist(address originalListOwner, address unauthorizedUser) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.reassignOwnershipOfPermittedContractReceiverAllowlist(listId, unauthorizedUser);
    }

    function testRenounceOwnershipOfOperatorWhitelist(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectEmit(true, true, true, false);
        emit ReassignedAllowlistOwnership(AllowlistTypes.Operators, listId, address(0));

        vm.prank(originalListOwner);
        validator.renounceOwnershipOfOperatorWhitelist(listId);
        assertEq(validator.operatorWhitelistOwners(listId), address(0));
    }

    function testRevertsWhenNonOwnerRenouncesOwnershipOfOperatorWhitelist(address originalListOwner, address unauthorizedUser) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.renounceOwnershipOfOperatorWhitelist(listId);
    }

    function testRenounceOwnershipOfPermittedContractReceiverAllowlist(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectEmit(true, true, true, false);
        emit ReassignedAllowlistOwnership(AllowlistTypes.PermittedContractReceivers, listId, address(0));

        vm.prank(originalListOwner);
        validator.renounceOwnershipOfPermittedContractReceiverAllowlist(listId);
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), address(0));
    }

    function testRevertsWhenNonOwnerRenouncesOwnershipOfPermittedContractReceiversAllowlist(address originalListOwner, address unauthorizedUser) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.renounceOwnershipOfPermittedContractReceiverAllowlist(listId);
    }

    function testSetTransferSecurityLevelOfCollection(address creator, uint8 levelUint8) public {
        vm.assume(creator != address(0));
        vm.assume(levelUint8 >= 0 && levelUint8 <= 6);

        TransferSecurityLevels level = TransferSecurityLevels(levelUint8);

        vm.startPrank(creator);
        ERC721CMock token = new ERC721CMock();

        vm.expectEmit(true, false, false, true);
        emit SetTransferSecurityLevel(address(token), level);

        validator.setTransferSecurityLevelOfCollection(address(token), level);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = validator.getCollectionSecurityPolicy(address(token));
        assertTrue(securityPolicy.transferSecurityLevel == level);
    }

    function testSetOperatorWhitelistOfCollection(address creator) public {
        vm.assume(creator != address(0));
        
        vm.startPrank(creator);
        ERC721CMock token = new ERC721CMock();

        uint120 listId = validator.createOperatorWhitelist("test");

        vm.expectEmit(true, true, true, false);
        emit SetAllowlist(AllowlistTypes.Operators, address(token), listId);

        validator.setOperatorWhitelistOfCollection(address(token), listId);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = validator.getCollectionSecurityPolicy(address(token));
        assertTrue(securityPolicy.operatorWhitelistId == listId);
    }

    function testRevertsWhenSettingOperatorWhitelistOfCollectionToInvalidListId(address creator, uint120 listId) public {
        vm.assume(creator != address(0));
        vm.assume(listId > 1);
        
        vm.startPrank(creator);
        ERC721CMock token = new ERC721CMock();

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistDoesNotExist.selector);
        validator.setOperatorWhitelistOfCollection(address(token), listId);
    }

    function testRevertsWhenUnauthorizedUserSetsOperatorWhitelistOfCollection(address creator, address unauthorizedUser) public {
        vm.assume(creator != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(creator != unauthorizedUser);
                
        vm.prank(creator);
        ERC721CMock token = new ERC721CMock();

        vm.startPrank(unauthorizedUser);
        uint120 listId = validator.createOperatorWhitelist("naughty list");

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT.selector);
        validator.setOperatorWhitelistOfCollection(address(token), listId);
        vm.stopPrank();
    }

    function testSetPermittedContractReceiverAllowlistOfCollection(address creator) public {
        vm.assume(creator != address(0));
        
        vm.startPrank(creator);
        ERC721CMock token = new ERC721CMock();

        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");

        vm.expectEmit(true, true, true, false);
        emit SetAllowlist(AllowlistTypes.PermittedContractReceivers, address(token), listId);

        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), listId);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = validator.getCollectionSecurityPolicy(address(token));
        assertTrue(securityPolicy.permittedContractReceiversId == listId);
    }

    function testRevertsWhenSettingPermittedContractReceiverAllowlistOfCollectionToInvalidListId(address creator, uint120 listId) public {
        vm.assume(creator != address(0));
        vm.assume(listId > 0);
        
        vm.startPrank(creator);
        ERC721CMock token = new ERC721CMock();

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistDoesNotExist.selector);
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), listId);
    }

    function testRevertsWhenUnauthorizedUserSetsPermittedContractReceiverAllowlistOfCollection(address creator, address unauthorizedUser) public {
        vm.assume(creator != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(creator != unauthorizedUser);
                
        vm.prank(creator);
        ERC721CMock token = new ERC721CMock();

        vm.startPrank(unauthorizedUser);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("naughty list");

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT.selector);
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), listId);
        vm.stopPrank();
    }

    function testAddToOperatorWhitelist(address originalListOwner, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(operator != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");

        vm.expectEmit(true, true, true, false);
        emit AddedToAllowlist(AllowlistTypes.Operators, listId, operator);

        validator.addOperatorToWhitelist(listId, operator);
        vm.stopPrank();

        assertTrue(validator.isOperatorWhitelisted(listId, operator));
    }

    function testRevertsWhenNonOwnerAddsOperatorToWhitelist(address originalListOwner, address unauthorizedUser, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(operator != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertEq(validator.operatorWhitelistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.addOperatorToWhitelist(listId, operator);
    }

    function testRevertsWhenOperatorAddedToWhitelistAgain(address originalListOwner, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(operator != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        validator.addOperatorToWhitelist(listId, operator);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AddressAlreadyAllowed.selector);
        validator.addOperatorToWhitelist(listId, operator);
        vm.stopPrank();
    }

    function testAddToPermittedContractReceiverToAllowlist(address originalListOwner, address receiver) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(receiver != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");

        vm.expectEmit(true, true, true, false);
        emit AddedToAllowlist(AllowlistTypes.PermittedContractReceivers, listId, receiver);

        validator.addPermittedContractReceiverToAllowlist(listId, receiver);
        vm.stopPrank();

        assertTrue(validator.isContractReceiverPermitted(listId, receiver));
    }

    function testRevertsWhenNonOwnerAddsPermittedContractReceiverToAllowlist(address originalListOwner, address unauthorizedUser, address receiver) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(receiver != address(0));
        vm.assume(originalListOwner != unauthorizedUser);

        vm.prank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertEq(validator.permittedContractReceiverAllowlistOwners(listId), originalListOwner);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerDoesNotOwnAllowlist.selector);
        vm.prank(unauthorizedUser);
        validator.addPermittedContractReceiverToAllowlist(listId, receiver);
    }

    function testRevertsWhenReceiverAddedToPermittedContractReceiversAllowlistAgain(address originalListOwner, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(operator != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        validator.addPermittedContractReceiverToAllowlist(listId, operator);

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AddressAlreadyAllowed.selector);
        validator.addPermittedContractReceiverToAllowlist(listId, operator);
        vm.stopPrank();
    }

    function testRemoveOperatorFromWhitelist(address originalListOwner, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(operator != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        validator.addOperatorToWhitelist(listId, operator);
        assertTrue(validator.isOperatorWhitelisted(listId, operator));

        vm.expectEmit(true, true, true, false);
        emit RemovedFromAllowlist(AllowlistTypes.Operators, listId, operator);

        validator.removeOperatorFromWhitelist(listId, operator);

        assertFalse(validator.isOperatorWhitelisted(listId, operator));
        vm.stopPrank();
    }

    function testRevertsWhenUnwhitelistedOperatorRemovedFromWhitelist(address originalListOwner, address operator) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(operator != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");
        assertFalse(validator.isOperatorWhitelisted(listId, operator));

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AddressNotAllowed.selector);
        validator.removeOperatorFromWhitelist(listId, operator);
        vm.stopPrank();
    }

    function testRemoveReceiverFromPermittedContractReceiverAllowlist(address originalListOwner, address receiver) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(receiver != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        validator.addPermittedContractReceiverToAllowlist(listId, receiver);
        assertTrue(validator.isContractReceiverPermitted(listId, receiver));

        vm.expectEmit(true, true, true, false);
        emit RemovedFromAllowlist(AllowlistTypes.PermittedContractReceivers, listId, receiver);

        validator.removePermittedContractReceiverFromAllowlist(listId, receiver);

        assertFalse(validator.isContractReceiverPermitted(listId, receiver));
        vm.stopPrank();
    }

    function testRevertsWhenUnallowedReceiverRemovedFromPermittedContractReceiverAllowlist(address originalListOwner, address receiver) public {
        vm.assume(originalListOwner != address(0));
        vm.assume(receiver != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");
        assertFalse(validator.isContractReceiverPermitted(listId, receiver));

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AddressNotAllowed.selector);
        validator.removePermittedContractReceiverFromAllowlist(listId, receiver);
        vm.stopPrank();
    }

    function testAddManyOperatorsToWhitelist(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createOperatorWhitelist("test");

        for (uint i = 1; i <= 10; i++) {
            validator.addOperatorToWhitelist(listId, vm.addr(i));
        }
        vm.stopPrank();

        for (uint i = 1; i <= 10; i++) {
            assertTrue(validator.isOperatorWhitelisted(listId, vm.addr(i)));
        }

        address[] memory whitelistedOperators = validator.getWhitelistedOperators(listId);
        assertEq(whitelistedOperators.length, 10);

        for(uint i = 0; i < whitelistedOperators.length; i++) {
            assertEq(vm.addr(i + 1), whitelistedOperators[i]);
        }
    }

    function testAddManyReceiversToPermittedContractReceiversAllowlist(address originalListOwner) public {
        vm.assume(originalListOwner != address(0));
        
        vm.startPrank(originalListOwner);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("test");

        for (uint i = 1; i <= 10; i++) {
            validator.addPermittedContractReceiverToAllowlist(listId, vm.addr(i));
        }
        vm.stopPrank();

        for (uint i = 1; i <= 10; i++) {
            assertTrue(validator.isContractReceiverPermitted(listId, vm.addr(i)));
        }

        address[] memory permittedContractReceivers = validator.getPermittedContractReceivers(listId);
        assertEq(permittedContractReceivers.length, 10);

        for(uint i = 0; i < permittedContractReceivers.length; i++) {
            assertEq(vm.addr(i + 1), permittedContractReceivers[i]);
        }
    }

    function testSupportedInterfaces() public {
        assertEq(validator.supportsInterface(type(ITransferValidator).interfaceId), true);
        assertEq(validator.supportsInterface(type(ITransferSecurityRegistry).interfaceId), true);
        assertEq(validator.supportsInterface(type(ICreatorTokenTransferValidator).interfaceId), true);
        assertEq(validator.supportsInterface(type(IEOARegistry).interfaceId), true);
        assertEq(validator.supportsInterface(type(IERC165).interfaceId), true);
    }
}