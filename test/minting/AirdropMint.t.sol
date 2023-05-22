// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../mocks/minting/AirdropMintMock.sol";
import "../mocks/ClonerMock.sol";
import "./MaxSupply.t.sol";

contract AirdropMintConstructableTest is MaxSupplyTest {
    AirdropMintMock token;

    function setUp() public {
        token = new AirdropMintMock(100, 110, 10);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorMintableToken) {
        vm.prank(creator);
        return ITestCreatorMintableToken(address(new AirdropMintMock(100, 90, 10)));
    }

    function testAirdropMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        assertEq(token.getNextTokenId(), 1);
        assertEq(token.remainingAirdropSupply(), 100);
        token.airdropMint(receivers);

        for (uint256 i = 1; i <= 100; ++i) {
            assertEq(token.ownerOf(i), receivers[i - 1]);
            assertEq(token.balanceOf(receivers[i - 1]), 1);
        }
        assertEq(token.getNextTokenId(), 101);
        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testAirdropMintMultipleAirdrops(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers1 = new address[](50);
        address[] memory receivers2 = new address[](50);
        for (uint256 i = 0; i < 50; ++i) {
            receivers1[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
            receivers2[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        assertEq(token.getNextTokenId(), 1);
        assertEq(token.remainingAirdropSupply(), 100);
        token.airdropMint(receivers1);

        assertEq(token.getNextTokenId(), 51);
        assertEq(token.remainingAirdropSupply(), 50);
        token.airdropMint(receivers2);

        assertEq(token.getNextTokenId(), 101);
        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testAirdropMintNotOwner(uint256 nonce, bytes32 sample, address badUser) public {
        vm.assume(badUser != address(this));
        vm.assume(badUser.code.length == 0);
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        vm.prank(badUser);
        vm.expectRevert("Ownable: caller is not the owner");
        token.airdropMint(receivers);
    }

    function testMintToZeroAddress() public {
        address[] memory receivers = new address[](1);
        receivers[0] = address(0);

        vm.expectRevert(AirdropMintBase.AirdropMint__CannotMintToZeroAddress.selector);
        token.airdropMint(receivers);
    }

    function testZeroLengthArrayMint() public {
        address[] memory receivers = new address[](0);

        vm.expectRevert(AirdropMintBase.AirdropMint__AirdropBatchSizeMustBeGreaterThanZero.selector);
        token.airdropMint(receivers);
    }

    function testZeroAddressMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 99; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }
        receivers[99] = address(0);

        vm.expectRevert(AirdropMintBase.AirdropMint__CannotMintToZeroAddress.selector);
        token.airdropMint(receivers);
    }

    function testMaxSupplyExceededMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        token.airdropMint(receivers);

        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyExceeded.selector);
        token.airdropMint(receivers);
    }

    function testMaxSupplyMaxUint256() public {
        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256.selector);
        new AirdropMintMock(type(uint256).max, 110, 10);
    }

    function testMaxSupplyZero() public {
        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToZero.selector);
        new AirdropMintMock(0, 110, 10);
    }
}

contract AirdropMintInitializableTest is MaxSupplyInitializableTest {
    AirdropMintInitializableMock token;
    AirdropMintInitializableMock referenceToken;

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorMintableToken) {
        referenceToken = new AirdropMintInitializableMock();
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

    function _deployUninitializedMaxSupply(address creator)
        internal
        virtual
        override
        returns (ITestCreatorMintableToken)
    {
        referenceToken = new AirdropMintInitializableMock();
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

    function setUp() public override {
        super.setUp();

        referenceToken = new AirdropMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxAirdropSupply.selector;
        initializationArguments[1] = abi.encode(100);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(110, 10);

        token = AirdropMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
    }

    function testInitializeMaxAirdropSupply() public {
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[1] = abi.encode(110, 10);

        token = AirdropMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        assertEq(token.remainingAirdropSupply(), 0);

        token.initializeMaxAirdropSupply(100);

        assertEq(token.remainingAirdropSupply(), 100);
    }

    function testInitializeMaxAirdropSupplyAlreadyInitialized() public {
        vm.expectRevert(AirdropMintInitializable.AirdropMintInitializable__MaxAirdropSupplyAlreadyInitialized.selector);
        token.initializeMaxAirdropSupply(100);
    }

    function testInitializeMaxAirdropSupplyNotOwner(address badUser) public {
        vm.assume(badUser != address(this));
        vm.prank(badUser);
        vm.expectRevert("Ownable: caller is not the owner");
        token.initializeMaxAirdropSupply(100);
    }

    function testInitializeMaxAirdropSupplyMaxUint256() public {
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[1] = abi.encode(110, 10);

        token = AirdropMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        assertEq(token.remainingAirdropSupply(), 0);

        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256.selector);
        token.initializeMaxAirdropSupply(type(uint256).max);

        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testInitializeMaxAirdropSupplyZero() public {
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[1] = abi.encode(110, 10);

        token = AirdropMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        assertEq(token.remainingAirdropSupply(), 0);

        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToZero.selector);
        token.initializeMaxAirdropSupply(0);

        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testInitializeMaxSupply() public {
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMaxAirdropSupply.selector;
        initializationArguments[1] = abi.encode(100);

        token = AirdropMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        assertEq(token.maxSupply(), 0);
        assertEq(token.remainingOwnerMints(), 0);

        token.initializeMaxSupply(110, 10);

        assertEq(token.maxSupply(), 110);
        assertEq(token.remainingOwnerMints(), 10);
    }

    function testAirdropMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        assertEq(token.getNextTokenId(), 1);
        assertEq(token.remainingAirdropSupply(), 100);
        token.airdropMint(receivers);

        for (uint256 i = 1; i <= 100; ++i) {
            assertEq(token.ownerOf(i), receivers[i - 1]);
            assertEq(token.balanceOf(receivers[i - 1]), 1);
        }
        assertEq(token.getNextTokenId(), 101);
        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testAirdropMintMultipleAirdrops(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers1 = new address[](50);
        address[] memory receivers2 = new address[](50);
        for (uint256 i = 0; i < 50; ++i) {
            receivers1[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
            receivers2[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        assertEq(token.getNextTokenId(), 1);
        assertEq(token.remainingAirdropSupply(), 100);
        token.airdropMint(receivers1);

        assertEq(token.getNextTokenId(), 51);
        assertEq(token.remainingAirdropSupply(), 50);
        token.airdropMint(receivers2);

        assertEq(token.getNextTokenId(), 101);
        assertEq(token.remainingAirdropSupply(), 0);
    }

    function testAirdropMintNotOwner(uint256 nonce, bytes32 sample, address badUser) public {
        vm.assume(badUser != address(this));
        vm.assume(badUser.code.length == 0);
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        vm.prank(badUser);
        vm.expectRevert("Ownable: caller is not the owner");
        token.airdropMint(receivers);
    }

    function testMintToZeroAddress() public {
        address[] memory receivers = new address[](1);
        receivers[0] = address(0);

        vm.expectRevert(AirdropMintBase.AirdropMint__CannotMintToZeroAddress.selector);
        token.airdropMint(receivers);
    }

    function testZeroLengthArrayMint() public {
        address[] memory receivers = new address[](0);

        vm.expectRevert(AirdropMintBase.AirdropMint__AirdropBatchSizeMustBeGreaterThanZero.selector);
        token.airdropMint(receivers);
    }

    function testZeroAddressMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 99; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }
        receivers[99] = address(0);

        vm.expectRevert(AirdropMintBase.AirdropMint__CannotMintToZeroAddress.selector);
        token.airdropMint(receivers);
    }

    function testMaxSupplyExceededMint(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);
        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            ++nonce;
        }

        token.airdropMint(receivers);

        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyExceeded.selector);
        token.airdropMint(receivers);
    }

    function testMaxSupplyMaxUint256() public {
        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256.selector);
        new AirdropMintMock(type(uint256).max, 110, 10);
    }

    function testMaxSupplyZero() public {
        vm.expectRevert(AirdropMintBase.AirdropMint__MaxAirdropSupplyCannotBeSetToZero.selector);
        new AirdropMintMock(0, 110, 10);
    }
}
