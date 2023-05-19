// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../mocks/minting/AirdropMintMock.sol";
import "../mocks/ClonerMock.sol";
import "../interfaces/ITestCreatorMintableToken.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

abstract contract MaxSupplyTest is Test {
    function _deployNewToken(address creator) internal virtual returns (ITestCreatorMintableToken) {
        vm.prank(creator);
        return ITestCreatorMintableToken(address(new AirdropMintMock(100, 90, 10)));
    }

    function testOwnerMint(address to, uint256 quantity, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(to != address(0));
        vm.assume(quantity > 0);

        ITestCreatorMintableToken token = _deployNewToken(creator);
        uint256 maxOwnerMints = token.remainingOwnerMints();
        vm.assume(maxOwnerMints >= quantity);

        vm.prank(creator);
        token.ownerMint(to, quantity);
        assertEq(token.balanceOf(to), quantity);
        assertEq(token.remainingOwnerMints(), maxOwnerMints - quantity);
    }

    function testOwnerMintZeroAmount(address to, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(to != address(0));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        uint256 maxOwnerMints = token.remainingOwnerMints();

        vm.prank(creator);
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__MintedQuantityMustBeGreaterThanZero.selector);
        token.ownerMint(to, 0);
        assertEq(token.balanceOf(to), 0);
        assertEq(token.remainingOwnerMints(), maxOwnerMints);
    }

    function testOwnerMintNotOwner(address to, uint256 quantity, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(to != address(0));
        vm.assume(to != creator);
        vm.assume(quantity > 0);

        ITestCreatorMintableToken token = _deployNewToken(creator);
        uint256 maxOwnerMints = token.remainingOwnerMints();
        vm.assume(maxOwnerMints >= quantity);

        vm.prank(to);
        vm.expectRevert("Ownable: caller is not the owner");
        token.ownerMint(to, quantity);
        assertEq(token.balanceOf(to), 0);
        assertEq(token.remainingOwnerMints(), maxOwnerMints);
    }

    function testOwnerMintToAddressZero(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        uint256 maxOwnerMints = token.remainingOwnerMints();

        vm.prank(creator);
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__CannotMintToAddressZero.selector);
        token.ownerMint(address(0), 1);
        assertEq(token.remainingOwnerMints(), maxOwnerMints);
    }

    function testOwnerMintMoreThanMaxOwnerMints(address to, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(to != address(0));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        uint256 maxOwnerMints = token.remainingOwnerMints();

        vm.prank(creator);
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints.selector);
        token.ownerMint(to, maxOwnerMints + 1);
        assertEq(token.remainingOwnerMints(), maxOwnerMints);
    }
}

abstract contract MaxSupplyInitializableTest is MaxSupplyTest {
    ClonerMock cloner;

    function setUp() public virtual {
        cloner = new ClonerMock();
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorMintableToken) {
        AirdropMintInitializableMock referenceToken = new AirdropMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxAirdropSupply.selector;
        initializationArguments[1] = abi.encode(100);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(110, 10);

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function _deployUninitializedMaxSupply(address creator) internal virtual returns (ITestCreatorMintableToken) {
        AirdropMintInitializableMock referenceToken = new AirdropMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxAirdropSupply.selector;
        initializationArguments[1] = abi.encode(100);

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function testIsInitialized(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        assert(token.maxSupplyInitialized());
    }

    function testInitializeMaxSupplyNotOwner(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployUninitializedMaxSupply(creator);

        vm.expectRevert("Ownable: caller is not the owner");
        token.initializeMaxSupply(110, 10);
    }

    function testInitializeMaxSupplyAlreadyInitialized(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);

        vm.prank(creator);
        vm.expectRevert(MaxSupplyInitializable.InitializableMaxSupplyBase__MaxSupplyAlreadyInitialized.selector);
        token.initializeMaxSupply(110, 10);
    }

    function testInitializeMaxSupplyUint256Max(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployUninitializedMaxSupply(creator);

        vm.prank(creator);
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256.selector);
        token.initializeMaxSupply(type(uint256).max, 10);
    }
}

contract MaxSupplyTest_Private is Test {
    function testOwnerMintMoreThanMaxSupplyLessThanMaxOwnerMints(address to) public {
        vm.assume(to != address(0));
        ITestCreatorMintableToken token = ITestCreatorMintableToken(address(new AirdropMintMock(100, 9, 10)));
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__MaxSupplyExceeded.selector);
        token.ownerMint(to, 10);
    }

    function testSetMaxSupplyUint256() public {
        vm.expectRevert(MaxSupplyBase.MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256.selector);
        new AirdropMintMock(100, type(uint256).max, 10);
    }
}
