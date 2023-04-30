// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ContractMock.sol";
import "./mocks/ERC1155CMock.sol";
import "./interfaces/ITestCreatorToken1155.sol";
import "contracts/utils/TransferPolicy.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";

contract CreatorTokenTransferValidatorERC1155Test is Test {
    using EnumerableSet for EnumerableSet.AddressSet;

    event AddedToAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event CreatedAllowlist(AllowlistTypes indexed kind, uint256 indexed id, string indexed name);
    event ReassignedAllowlistOwnership(AllowlistTypes indexed kind, uint256 indexed id, address indexed newOwner);
    event RemovedFromAllowlist(AllowlistTypes indexed kind, uint256 indexed id, address indexed account);
    event SetAllowlist(AllowlistTypes indexed kind, address indexed collection, uint120 indexed id);
    event SetTransferSecurityLevel(address indexed collection, TransferSecurityLevels level);

    bytes32 private saltValue = bytes32(uint256(8946686101848117716489848979750688532688049124417468924436884748620307827805));
    
    CreatorTokenTransferValidator public validator;

    address validatorDeployer;
    address whitelistedOperator;

    function setUp() public virtual {
        validatorDeployer = vm.addr(1);
        vm.startPrank(validatorDeployer);
        validator = new CreatorTokenTransferValidator{salt: saltValue}();
        vm.stopPrank();
        
        whitelistedOperator = vm.addr(2);

        vm.prank(validatorDeployer);
        validator.addOperatorToWhitelist(1, whitelistedOperator);
    }

    function _deployNewToken(address creator) internal virtual returns (ITestCreatorToken1155) {
        vm.prank(creator);
        return ITestCreatorToken1155(address(new ERC1155CMock()));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual {
        ERC1155CMock(tokenAddress).mint(to, tokenId, amount);
    }

    function testDeterministicAddressForCreatorTokenValidator() public {
        assertEq(address(validator), 0x6583De8C67705Ef6B968EAEB88366eC969A05060);
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

    function testGetTransferValidatorReturnsAddressZeroBeforeValidatorIsSet(address creator) public {
        vm.assume(creator != address(0));

        ITestCreatorToken1155 token = _deployNewToken(creator);
        assertEq(address(token.getTransferValidator()), address(0));
    }

    function testRevertsWhenSetTransferValidatorCalledWithContractThatDoesNotImplementRequiredInterface(address creator) public {
        vm.assume(creator != address(0));

        ITestCreatorToken1155 token = _deployNewToken(creator);
        
        vm.startPrank(creator);
        address invalidContract = address(new ContractMock());
        vm.expectRevert(CreatorTokenBase.CreatorTokenBase__InvalidTransferValidatorContract.selector);
        token.setTransferValidator(invalidContract);
        vm.stopPrank();
    }

    function testAllowsAlternativeValidatorsToBeSetIfTheyImplementRequiredInterface(address creator) public {
        vm.assume(creator != address(0));

        ITestCreatorToken1155 token = _deployNewToken(creator);
        
        vm.startPrank(creator);
        address alternativeValidator = address(new CreatorTokenTransferValidator());
        token.setTransferValidator(alternativeValidator);
        vm.stopPrank();

        assertEq(address(token.getTransferValidator()), alternativeValidator);
    }

    function testAllowsValidatorToBeSetBackToZeroAddress(address creator) public {
        vm.assume(creator != address(0));

        ITestCreatorToken1155 token = _deployNewToken(creator);
        
        vm.startPrank(creator);
        address alternativeValidator = address(new CreatorTokenTransferValidator());
        token.setTransferValidator(alternativeValidator);
        token.setTransferValidator(address(0));
        vm.stopPrank();

        assertEq(address(token.getTransferValidator()), address(0));
    }

    function testGetSecurityPolicyReturnsEmptyPolicyWhenNoValidatorIsSet(address creator) public {
        vm.assume(creator != address(0));
        ITestCreatorToken1155 token = _deployNewToken(creator);
        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertEq(uint8(securityPolicy.transferSecurityLevel), uint8(TransferSecurityLevels.Zero));
        assertEq(uint256(securityPolicy.operatorWhitelistId), 0);
        assertEq(uint256(securityPolicy.permittedContractReceiversId), 0);
    }

    function testGetSecurityPolicyReturnsExpectedSecurityPolicy(address creator, uint8 levelUint8) public {
        vm.assume(creator != address(0));
        vm.assume(levelUint8 >= 0 && levelUint8 <= 6);

        TransferSecurityLevels level = TransferSecurityLevels(levelUint8);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        uint120 operatorWhitelistId = validator.createOperatorWhitelist("");
        uint120 permittedReceiversListId = validator.createPermittedContractReceiverAllowlist("");
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), operatorWhitelistId);
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), permittedReceiversListId);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertTrue(securityPolicy.transferSecurityLevel == level);
        assertEq(uint256(securityPolicy.operatorWhitelistId), operatorWhitelistId);
        assertEq(uint256(securityPolicy.permittedContractReceiversId), permittedReceiversListId);
    }

    function testSetCustomSecurityPolicy(address creator, uint8 levelUint8) public {
        vm.assume(creator != address(0));
        vm.assume(levelUint8 >= 0 && levelUint8 <= 6);

        TransferSecurityLevels level = TransferSecurityLevels(levelUint8);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        uint120 operatorWhitelistId = validator.createOperatorWhitelist("");
        uint120 permittedReceiversListId = validator.createPermittedContractReceiverAllowlist("");
        token.setToCustomSecurityPolicy(address(validator), level, operatorWhitelistId, permittedReceiversListId);
        vm.stopPrank();

        assertEq(address(token.getTransferValidator()), address(validator));

        CollectionSecurityPolicy memory securityPolicy = token.getSecurityPolicy();
        assertTrue(securityPolicy.transferSecurityLevel == level);
        assertEq(uint256(securityPolicy.operatorWhitelistId), operatorWhitelistId);
        assertEq(uint256(securityPolicy.permittedContractReceiversId), permittedReceiversListId);
    }

    function testSetTransferSecurityLevelOfCollection(address creator, uint8 levelUint8) public {
        vm.assume(creator != address(0));
        vm.assume(levelUint8 >= 0 && levelUint8 <= 6);

        TransferSecurityLevels level = TransferSecurityLevels(levelUint8);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        vm.expectEmit(true, false, false, true);
        emit SetTransferSecurityLevel(address(token), level);
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = validator.getCollectionSecurityPolicy(address(token));
        assertTrue(securityPolicy.transferSecurityLevel == level);
    }

    function testSetOperatorWhitelistOfCollection(address creator) public {
        vm.assume(creator != address(0));
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);

        uint120 listId = validator.createOperatorWhitelist("test");

        vm.expectEmit(true, true, true, false);
        emit SetAllowlist(AllowlistTypes.Operators, address(token), listId);

        validator.setOperatorWhitelistOfCollection(address(token), listId);
        vm.stopPrank();

        CollectionSecurityPolicy memory securityPolicy = validator.getCollectionSecurityPolicy(address(token));
        assertTrue(securityPolicy.operatorWhitelistId == listId);
    }

    //tokenMock.setToCustomSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);

    function testRevertsWhenSettingOperatorWhitelistOfCollectionToInvalidListId(address creator, uint120 listId) public {
        vm.assume(creator != address(0));
        vm.assume(listId > 1);
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.prank(creator);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistDoesNotExist.selector);
        validator.setOperatorWhitelistOfCollection(address(token), listId);
    }

    function testRevertsWhenUnauthorizedUserSetsOperatorWhitelistOfCollection(address creator, address unauthorizedUser) public {
        vm.assume(creator != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(creator != unauthorizedUser);
                
        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(unauthorizedUser);
        uint120 listId = validator.createOperatorWhitelist("naughty list");

        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerMustHaveElevatedPermissionsForSpecifiedNFT.selector);
        validator.setOperatorWhitelistOfCollection(address(token), listId);
        vm.stopPrank();
    }

    function testSetPermittedContractReceiverAllowlistOfCollection(address creator) public {
        vm.assume(creator != address(0));
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);

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
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.prank(creator);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__AllowlistDoesNotExist.selector);
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), listId);
    }

    function testRevertsWhenUnauthorizedUserSetsPermittedContractReceiverAllowlistOfCollection(address creator, address unauthorizedUser) public {
        vm.assume(creator != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(creator != unauthorizedUser);
                
        ITestCreatorToken1155 token = _deployNewToken(creator);

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

    function testWhitelistedOperatorsCanBeQueriedOnCreatorTokens(address creator, address operator1, address operator2, address operator3) public {
        vm.assume(creator != address(0));
        vm.assume(operator1 != address(0));
        vm.assume(operator2 != address(0));
        vm.assume(operator3 != address(0));
        vm.assume(operator1 != operator2);
        vm.assume(operator1 != operator3);
        vm.assume(operator2 != operator3);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        uint120 listId = validator.createOperatorWhitelist("");
        token.setTransferValidator(address(validator));
        validator.setOperatorWhitelistOfCollection(address(token), listId);
        validator.addOperatorToWhitelist(listId, operator1);
        validator.addOperatorToWhitelist(listId, operator2);
        validator.addOperatorToWhitelist(listId, operator3);
        vm.stopPrank();

        assertTrue(token.isOperatorWhitelisted(operator1));
        assertTrue(token.isOperatorWhitelisted(operator2));
        assertTrue(token.isOperatorWhitelisted(operator3));

        address[] memory allowedAddresses = token.getWhitelistedOperators();
        assertEq(allowedAddresses.length, 3);
        assertTrue(allowedAddresses[0] == operator1);
        assertTrue(allowedAddresses[1] == operator2);
        assertTrue(allowedAddresses[2] == operator3);
    }

    function testWhitelistedOperatorQueriesWhenNoTransferValidatorIsSet(address creator, address operator) public {
        vm.assume(creator != address(0));
        vm.assume(operator != address(0));
        ITestCreatorToken1155 token = _deployNewToken(creator);
        assertFalse(token.isOperatorWhitelisted(operator));
        address[] memory allowedAddresses = token.getWhitelistedOperators();
        assertEq(allowedAddresses.length, 0);
    }

    function testPermittedContractReceiversCanBeQueriedOnCreatorTokens(address creator, address receiver1, address receiver2, address receiver3) public {
        vm.assume(creator != address(0));
        vm.assume(receiver1 != address(0));
        vm.assume(receiver2 != address(0));
        vm.assume(receiver3 != address(0));
        vm.assume(receiver1 != receiver2);
        vm.assume(receiver1 != receiver3);
        vm.assume(receiver2 != receiver3);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        uint120 listId = validator.createPermittedContractReceiverAllowlist("");
        token.setTransferValidator(address(validator));
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), listId);
        validator.addPermittedContractReceiverToAllowlist(listId, receiver1);
        validator.addPermittedContractReceiverToAllowlist(listId, receiver2);
        validator.addPermittedContractReceiverToAllowlist(listId, receiver3);
        vm.stopPrank();

        assertTrue(token.isContractReceiverPermitted(receiver1));
        assertTrue(token.isContractReceiverPermitted(receiver2));
        assertTrue(token.isContractReceiverPermitted(receiver3));

        address[] memory allowedAddresses = token.getPermittedContractReceivers();
        assertEq(allowedAddresses.length, 3);
        assertTrue(allowedAddresses[0] == receiver1);
        assertTrue(allowedAddresses[1] == receiver2);
        assertTrue(allowedAddresses[2] == receiver3);
    }

    function testPermittedContractReceiverQueriesWhenNoTransferValidatorIsSet(address creator, address receiver) public {
        vm.assume(creator != address(0));
        vm.assume(receiver != address(0));
        ITestCreatorToken1155 token = _deployNewToken(creator);
        assertFalse(token.isContractReceiverPermitted(receiver));
        address[] memory allowedAddresses = token.getPermittedContractReceivers();
        assertEq(allowedAddresses.length, 0);
    }

    function testIsTransferAllowedReturnsTrueWhenNoTransferValidatorIsSet(address creator, address caller, address from, address to) public {
        vm.assume(creator != address(0));
        ITestCreatorToken1155 token = _deployNewToken(creator);
        assertTrue(token.isTransferAllowed(caller, from, to));
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

    function testPolicyLevelZeroPermitsAllTransfers(address creator, address caller, address from, address to) public {
        vm.assume(creator != address(0));
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), TransferSecurityLevels.Zero);
        vm.stopPrank();
        assertTrue(token.isTransferAllowed(caller, from, to));
    }

    function testWhitelistPoliciesWithOTCEnabledBlockTransfersWhenCallerNotWhitelistedOrOwner(address creator, address caller, address from, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.One, creator, caller, from, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.Three, creator, caller, from, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.Four, creator, caller, from, to, tokenId, amount);
    }

    function testWhitelistPoliciesWithOTCEnabledAllowTransfersWhenCalledByOwner(address creator, address tokenOwner, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyAllowsTransfersWhenCalledByOwner(TransferSecurityLevels.One, creator, tokenOwner, to, tokenId, amount);
        _testPolicyAllowsTransfersWhenCalledByOwner(TransferSecurityLevels.Three, creator, tokenOwner, to, tokenId, amount);
        _testPolicyAllowsTransfersWhenCalledByOwner(TransferSecurityLevels.Four, creator, tokenOwner, to, tokenId, amount);
    }

    function testWhitelistPoliciesWithOTCDisabledBlockTransfersWhenCallerNotWhitelistedOrOwner(address creator, address caller, address from, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.Two, creator, caller, from, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.Five, creator, caller, from, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(TransferSecurityLevels.Six, creator, caller, from, to, tokenId, amount);
    }

    function testWhitelistPoliciesWithOTCDisabledBlockTransfersWhenCalledByOwner(address creator, address tokenOwner, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyBlocksTransfersWhenCalledByOwner(TransferSecurityLevels.Two, creator, tokenOwner, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCalledByOwner(TransferSecurityLevels.Five, creator, tokenOwner, to, tokenId, amount);
        _testPolicyBlocksTransfersWhenCalledByOwner(TransferSecurityLevels.Six, creator, tokenOwner, to, tokenId, amount);
    }

    function testNoCodePoliciesBlockTransferWhenDestinationIsAContract(address creator, address caller, address from, uint256 tokenId, uint256 amount) public {
        _testPolicyBlocksTransfersToContractReceivers(TransferSecurityLevels.Three, creator, caller, from, tokenId, amount);
        _testPolicyBlocksTransfersToContractReceivers(TransferSecurityLevels.Five, creator, caller, from, tokenId, amount);
    }

    function testNoCodePoliciesAllowTransferToPermittedContractDestinations(address creator, address caller, address from, uint256 tokenId, uint256 amount) public {
        _testPolicyAllowsTransfersToPermittedContractReceivers(TransferSecurityLevels.Three, creator, caller, from, tokenId, amount);
        _testPolicyAllowsTransfersToPermittedContractReceivers(TransferSecurityLevels.Five, creator, caller, from, tokenId, amount);
    }

    function testEOAPoliciesBlockTransferWhenDestinationHasNotVerifiedSignature(address creator, address caller, address from, address to, uint256 tokenId, uint256 amount) public {
        _testPolicyBlocksTransfersToWalletsThatHaveNotVerifiedEOASignature(TransferSecurityLevels.Four, creator, caller, from, to, tokenId, amount);
        _testPolicyBlocksTransfersToWalletsThatHaveNotVerifiedEOASignature(TransferSecurityLevels.Six, creator, caller, from, to, tokenId, amount);
    }

    function testEOAPoliciesAllowTransferWhenDestinationHasVerifiedSignature(address creator, address caller, address from, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyAllowsTransfersToWalletsThatHaveVerifiedEOASignature(TransferSecurityLevels.Four, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsTransfersToWalletsThatHaveVerifiedEOASignature(TransferSecurityLevels.Six, creator, caller, from, to, tokenId, amount);
    }

    function testEOAPoliciesAllowTransferToPermittedContractDestinations(address creator, address caller, address from, uint256 tokenId, uint256 amount) public {
        _testPolicyAllowsTransfersToPermittedContractReceivers(TransferSecurityLevels.Four, creator, caller, from, tokenId, amount);
        _testPolicyAllowsTransfersToPermittedContractReceivers(TransferSecurityLevels.Six, creator, caller, from, tokenId, amount);
    }

    function testWhitelistPoliciesAllowAllTransfersWhenOperatorWhitelistIsEmpty(address creator, address caller, address from, uint160 toKey, uint256 tokenId, uint256 amount) public {
        address to = _verifyEOA(toKey);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.One, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.Two, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.Three, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.Four, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.Five, creator, caller, from, to, tokenId, amount);
        _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(TransferSecurityLevels.Six, creator, caller, from, to, tokenId, amount);
    }

    function _testPolicyAllowsAllTransfersWhenOperatorWhitelistIsEmpty(
        TransferSecurityLevels level,
        address creator,
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount) private {
        vm.assume(creator != address(0));
        vm.assume(caller != whitelistedOperator);
        vm.assume(caller != address(0));
        vm.assume(from != address(0));
        vm.assume(from != caller);
        vm.assume(to != address(0));
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 0);
        vm.stopPrank();

        assertTrue(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);
        
        vm.prank(from);
        token.setApprovalForAll(caller, true);

        vm.prank(caller);
        token.safeTransferFrom(from, to, tokenId, amount, "");
        assertEq(token.balanceOf(to, tokenId), amount);
    }

    function _testPolicyBlocksTransfersWhenCallerNotWhitelistedOrOwner(
        TransferSecurityLevels level, 
        address creator, 
        address caller, 
        address from, 
        address to,
        uint256 tokenId,
        uint256 amount) private {
        vm.assume(creator != address(0));
        vm.assume(caller != whitelistedOperator);
        vm.assume(caller != address(0));
        vm.assume(from != address(0));
        vm.assume(from != caller);
        vm.assume(from.code.length == 0);
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertFalse(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);

        vm.prank(from);
        token.setApprovalForAll(caller, true);

        vm.prank(caller);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator.selector);
        token.safeTransferFrom(from, to, tokenId, amount, "");
    }

    function _testPolicyAllowsTransfersWhenCalledByOwner(
        TransferSecurityLevels level, 
        address creator, 
        address tokenOwner, 
        address to,
        uint256 tokenId,
        uint256 amount) private {
        vm.assume(creator != address(0));
        vm.assume(tokenOwner != whitelistedOperator);
        vm.assume(tokenOwner != address(0));
        vm.assume(tokenOwner.code.length == 0);
        vm.assume(to != address(0));
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertTrue(token.isTransferAllowed(tokenOwner, tokenOwner, to));

        _mintToken(address(token), tokenOwner, tokenId, amount);
        
        vm.prank(tokenOwner);
        token.safeTransferFrom(tokenOwner, to, tokenId, amount, "");

        assertEq(token.balanceOf(to, tokenId), amount);
    }

    function _testPolicyBlocksTransfersWhenCalledByOwner(
        TransferSecurityLevels level, 
        address creator, 
        address tokenOwner, 
        address to,
        uint256 tokenId,
        uint256 amount) private {
        vm.assume(creator != address(0));
        vm.assume(tokenOwner != whitelistedOperator);
        vm.assume(tokenOwner != address(0));
        vm.assume(tokenOwner.code.length == 0);
        vm.assume(to != address(0));
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertFalse(token.isTransferAllowed(tokenOwner, tokenOwner, to));

        _mintToken(address(token), tokenOwner, tokenId, amount);
        
        vm.prank(tokenOwner);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__CallerMustBeWhitelistedOperator.selector);
        token.safeTransferFrom(tokenOwner, to, tokenId, amount, "");
    }

    function _testPolicyBlocksTransfersToContractReceivers(
        TransferSecurityLevels level,
        address creator,
        address caller,
        address from,
        uint256 tokenId,
        uint256 amount) private {
        
        vm.assume(creator != address(0));
        vm.assume(from != address(0));
        vm.assume(from.code.length == 0);
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        if(!validator.isOperatorWhitelisted(1, caller)) {
            vm.prank(validatorDeployer);
            validator.addOperatorToWhitelist(1, caller);
        }
        
        address to = address(new ContractMock());

        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertFalse(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);
        
        if(caller != from) {
            vm.prank(from);
            token.setApprovalForAll(caller, true);
        }

        vm.prank(caller);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__ReceiverMustNotHaveDeployedCode.selector);
        token.safeTransferFrom(from, to, tokenId, amount, "");
    }

    function _testPolicyBlocksTransfersToWalletsThatHaveNotVerifiedEOASignature(
        TransferSecurityLevels level,
        address creator,
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount) private {
        
        vm.assume(creator != address(0));
        vm.assume(caller != address(0));
        vm.assume(from != address(0));
        vm.assume(from.code.length == 0);
        vm.assume(to != address(0));
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        if(!validator.isOperatorWhitelisted(1, caller)) {
            vm.prank(validatorDeployer);
            validator.addOperatorToWhitelist(1, caller);
        }
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertFalse(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);
        
        if(caller != from) {
            vm.prank(from);
            token.setApprovalForAll(caller, true);
        }

        vm.prank(caller);
        vm.expectRevert(CreatorTokenTransferValidator.CreatorTokenTransferValidator__ReceiverProofOfEOASignatureUnverified.selector);
        token.safeTransferFrom(from, to, tokenId, amount, "");
    }

    function _testPolicyAllowsTransfersToWalletsThatHaveVerifiedEOASignature(
        TransferSecurityLevels level,
        address creator,
        address caller,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount) private {
        
        vm.assume(creator != address(0));
        vm.assume(caller != address(0));
        vm.assume(from != address(0));
        vm.assume(to != address(0));
        vm.assume(from.code.length == 0);
        vm.assume(to.code.length == 0);
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        if(!validator.isOperatorWhitelisted(1, caller)) {
            vm.prank(validatorDeployer);
            validator.addOperatorToWhitelist(1, caller);
        }
        
        ITestCreatorToken1155 token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        vm.stopPrank();

        assertTrue(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);
        
        if(caller != from) {
            vm.prank(from);
            token.setApprovalForAll(caller, true);
        }

        vm.prank(caller);
        token.safeTransferFrom(from, to, tokenId, amount, "");
        assertEq(token.balanceOf(to, tokenId), amount);
    }

    function _testPolicyAllowsTransfersToPermittedContractReceivers(
        TransferSecurityLevels level,
        address creator,
        address caller,
        address from,
        uint256 tokenId,
        uint256 amount) private {
        
        vm.assume(creator != address(0));
        vm.assume(from != address(0));
        vm.assume(from.code.length == 0);
        vm.assume(tokenId > 0);
        vm.assume(amount > 0);

        if(!validator.isOperatorWhitelisted(1, caller)) {
            vm.prank(validatorDeployer);
            validator.addOperatorToWhitelist(1, caller);
        }
        
        address to = address(new ContractMock());

        ITestCreatorToken1155 token = _deployNewToken(creator);

        vm.startPrank(creator);

        uint120 permittedContractReceiversListId = validator.createPermittedContractReceiverAllowlist("");
        validator.addPermittedContractReceiverToAllowlist(permittedContractReceiversListId, to);

        token.setTransferValidator(address(validator));
        validator.setTransferSecurityLevelOfCollection(address(token), level);
        validator.setOperatorWhitelistOfCollection(address(token), 1);
        validator.setPermittedContractReceiverAllowlistOfCollection(address(token), permittedContractReceiversListId);
        vm.stopPrank();

        assertTrue(token.isTransferAllowed(caller, from, to));

        _mintToken(address(token), from, tokenId, amount);
        
        if(caller != from) {
            vm.prank(from);
            token.setApprovalForAll(caller, true);
        }

        vm.prank(caller);
        token.safeTransferFrom(from, to, tokenId, amount, "");
        assertEq(token.balanceOf(to, tokenId), amount);
    }

    function _verifyEOA(uint160 toKey) private returns (address to) {
        vm.assume(toKey > 0 && toKey < type(uint160).max);
        to = vm.addr(toKey);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(toKey, ECDSA.toEthSignedMessageHash(bytes(validator.MESSAGE_TO_SIGN())));
        vm.prank(to);
        validator.verifySignatureVRS(v, r, s);
    }
}