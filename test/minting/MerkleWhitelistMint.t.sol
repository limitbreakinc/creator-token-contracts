// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MaxSupply.t.sol";
import "./ClaimPeriod.t.sol";
import "../mocks/minting/MerkleWhitelistMintMock.sol";
import "../mocks/ClonerMock.sol";
import "forge-std/console.sol";
import {Merkle} from "murky/Merkle.sol";

contract MerkleWhitelistMintConstructableTest is MaxSupplyTest, ClaimPeriodTest {
    MerkleWhitelistMintMock token;
    Merkle m;
    bytes32 root;
    bytes32[] data;
    address[] receivers;

    function _deployNewToken(address creator)
        internal
        override(MaxSupplyTest, ClaimPeriodTest)
        returns (ITestCreatorMintableToken)
    {
        vm.prank(creator);
        return ITestCreatorMintableToken(address(new MerkleWhitelistMintMock(100, 2, 110, 10)));
    }

    function setUp() public {
        token = new MerkleWhitelistMintMock(100, 2, 110, 10);

        m = new Merkle();

        uint160 nonce = uint160(uint256(keccak256(abi.encodePacked(address(this)))));
        uint160 maxVal = ~uint160(0) - uint160(11);
        nonce = nonce % maxVal;

        for (uint256 i = 0; i < 10; ++i) {
            receivers.push(address(nonce));
            data.push(keccak256(abi.encodePacked(receivers[i], uint256(1))));
            ++nonce;
        }

        root = m.getRoot(data);
    }

    function testOpenClaims(uint256 timestamp) public {
        timestamp = bound(timestamp, block.timestamp + 1, ~uint256(0));

        assertFalse(token.isClaimPeriodOpen());
        token.openClaims(timestamp);
        assertTrue(token.isClaimPeriodOpen());
    }

    function testOpenClaimsNotOwner(uint256 timestamp, address badUser) public {
        vm.assume(badUser != address(this));
        vm.assume(badUser.code.length == 0);
        timestamp = bound(timestamp, block.timestamp + 1, ~uint256(0));

        assertFalse(token.isClaimPeriodOpen());
        vm.prank(badUser);
        vm.expectRevert("Ownable: caller is not the owner");
        token.openClaims(timestamp);
        assertFalse(token.isClaimPeriodOpen());
    }

    function testSetMerkleRootImmutable() public {
        token.setMerkleRoot(root);
        token.setMerkleRoot(root);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootImmutable.selector);
        token.setMerkleRoot(root);
    }

    function testMintNoWhitelistSet() public {
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootHasNotBeenInitialized.selector);
        token.whitelistMint(1, proof);
    }

    function testMintNotOpen() public {
        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodIsNotOpen.selector);
        token.whitelistMint(1, proof);
    }

    function testSetRootToZero() public {
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootCannotBeZero.selector);
        token.setMerkleRoot(0);
    }

    function testSetMaxMintsZero() public {
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MaxMintsMustBeGreaterThanZero.selector);
        new MerkleWhitelistMintMock(0, 1, 110, 10);
    }

    function testSetRootChangeAmountZero() public {
        vm.expectRevert(
            MerkleWhitelistMintBase
                .MerkleWhitelistMint__PermittedNumberOfMerkleRootChangesMustBeGreaterThanZero
                .selector
        );
        new MerkleWhitelistMintMock(10, 0, 110, 10);
    }

    function testMintAlreadyMinted() public {
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        token.whitelistMint(1, proof);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__AddressHasAlreadyClaimed.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testMintInvalidProof() public {
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory invalidProof = m.getProof(data, 1);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, invalidProof);
        vm.stopPrank();
    }

    function testMintClaimMoreThanMax() public {
        token = new MerkleWhitelistMintMock(1, 1, 1, 0);
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        token.whitelistMint(1, proof);
        vm.stopPrank();

        vm.startPrank(receivers[1]);
        proof = m.getProof(data, 1);
        vm.expectRevert(
            MerkleWhitelistMintBase.MerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints.selector
        );
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testMintAll() public {
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        assertEq(token.remainingMerkleMints(), 100);
        for (uint256 i = 0; i < 10; ++i) {
            vm.startPrank(receivers[i]);
            bytes32[] memory proof = m.getProof(data, i);
            token.whitelistMint(1, proof);

            assertEq(1, token.balanceOf(receivers[i]));
            assertEq(token.ownerOf(i + 1), receivers[i]);
            assert(token.isWhitelistClaimed(receivers[i]));
            vm.stopPrank();
        }
        assertEq(token.remainingMerkleMints(), 90);
    }

    function testMintMultipleWhitelists(uint256 length, uint256 salt) public {
        length = bound(length, 2, 20);
        salt = bound(salt, 1, ~uint256(0));

        address[] memory toAddresses = new address[](length);
        bytes32[] memory secondData = new bytes32[](length);
        bytes32 secondRoot;

        for (uint256 i = 0; i < length; ++i) {
            toAddresses[i] = address(uint160(uint256(keccak256(abi.encodePacked(i, salt)))));
            secondData[i] = keccak256(abi.encodePacked(toAddresses[i], uint256(1)));
        }

        secondRoot = m.getRoot(secondData);

        token = new MerkleWhitelistMintMock(length + 10, 2, length + 10, 0);
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        uint256 tokensMinted;
        bytes32[] memory proof;

        for (uint256 i = 0; i < 9; ++i) {
            vm.startPrank(receivers[i]);
            proof = m.getProof(data, i);
            token.whitelistMint(1, proof);
            tokensMinted++;

            assertEq(1, token.balanceOf(receivers[i]));
            assertEq(token.ownerOf(tokensMinted), receivers[i]);
            vm.stopPrank();
        }

        vm.startPrank(toAddresses[0]);
        proof = m.getProof(secondData, 0);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();

        token.setMerkleRoot(secondRoot);

        for (uint256 i = 0; i < length; ++i) {
            vm.startPrank(toAddresses[i]);
            proof = m.getProof(secondData, i);
            token.whitelistMint(1, proof);
            tokensMinted++;

            assertEq(1, token.balanceOf(toAddresses[i]));
            assertEq(token.ownerOf(tokensMinted), toAddresses[i]);
            vm.stopPrank();
        }

        vm.startPrank(receivers[9]);
        proof = m.getProof(data, 9);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testSetMerkleRootNotOwner(address nonOwner) public {
        vm.assume(nonOwner != token.owner());
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        token.setMerkleRoot(bytes32(0));
        vm.stopPrank();
    }
}

contract MerkleWhitelistMintInitializableTest is MaxSupplyInitializableTest, ClaimPeriodTest {
    MerkleWhitelistMintInitializableMock referenceToken;
    MerkleWhitelistMintInitializableMock token;
    Merkle m;
    bytes32 root;
    bytes32[] data;
    address[] receivers;

    function _deployNewToken(address creator)
        internal
        virtual
        override(MaxSupplyInitializableTest, ClaimPeriodTest)
        returns (ITestCreatorMintableToken)
    {
        referenceToken = new MerkleWhitelistMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] =
            referenceToken.initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges.selector;
        initializationArguments[1] = abi.encode(100, 2);

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
        referenceToken = new MerkleWhitelistMintInitializableMock();
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] =
            referenceToken.initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges.selector;
        initializationArguments[1] = abi.encode(100, 2);

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function setUp() public override {
        cloner = new ClonerMock();

        referenceToken = new MerkleWhitelistMintInitializableMock();

        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] =
            referenceToken.initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges.selector;
        initializationArguments[1] = abi.encode(100, 2);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(110, 10);

        token = MerkleWhitelistMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        m = new Merkle();

        uint160 nonce = uint160(uint256(keccak256(abi.encodePacked(address(this)))));
        uint160 maxVal = ~uint160(0) - uint160(11);
        nonce = nonce % maxVal;

        for (uint256 i = 0; i < 10; ++i) {
            receivers.push(address(nonce));
            data.push(keccak256(abi.encodePacked(receivers[i], uint256(1))));
            ++nonce;
        }

        root = m.getRoot(data);
    }

    function testInitializeAlreadyInitialized() public {
        vm.expectRevert(
            MerkleWhitelistMintInitializable.MerkleWhitelistMintInitializable__MerkleSupplyAlreadyInitialized.selector
        );
        token.initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges(1000, 5);
    }

    function testOpenClaimsInit(uint256 timestamp) public {
        timestamp = bound(timestamp, block.timestamp + 1, ~uint256(0));

        assertFalse(token.isClaimPeriodOpen());
        token.openClaims(timestamp);
        assertTrue(token.isClaimPeriodOpen());
    }

    function testOpenClaimsNotOwner(uint256 timestamp, address badUser) public {
        vm.assume(badUser != address(this));
        vm.assume(badUser.code.length == 0);
        timestamp = bound(timestamp, block.timestamp + 1, ~uint256(0));

        assertFalse(token.isClaimPeriodOpen());
        vm.prank(badUser);
        vm.expectRevert("Ownable: caller is not the owner");
        token.openClaims(timestamp);
        assertFalse(token.isClaimPeriodOpen());
    }

    function testSetMerkleRootImmutable() public {
        token.setMerkleRoot(root);
        token.setMerkleRoot(root);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootImmutable.selector);
        token.setMerkleRoot(root);
    }

    function testMintNoWhitelistSet() public {
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootHasNotBeenInitialized.selector);
        token.whitelistMint(1, proof);
    }

    function testMintNotOpen() public {
        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodIsNotOpen.selector);
        token.whitelistMint(1, proof);
    }

    function testSetRootToZero() public {
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__MerkleRootCannotBeZero.selector);
        token.setMerkleRoot(0);
    }

    function testMintAlreadyMinted() public {
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        token.whitelistMint(1, proof);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__AddressHasAlreadyClaimed.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testMintInvalidProof() public {
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory invalidProof = m.getProof(data, 1);

        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, invalidProof);
        vm.stopPrank();
    }

    function testMintClaimMoreThanMax() public {
        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] =
            referenceToken.initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges.selector;
        initializationArguments[1] = abi.encode(1, 1);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(110, 10);
        token = MerkleWhitelistMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        vm.startPrank(receivers[0]);
        bytes32[] memory proof = m.getProof(data, 0);
        token.whitelistMint(1, proof);
        vm.stopPrank();

        vm.startPrank(receivers[1]);
        proof = m.getProof(data, 1);
        vm.expectRevert(
            MerkleWhitelistMintBase.MerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints.selector
        );
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testMintAllInit() public {
        token.setMerkleRoot(root);
        console.logBytes32(token.getMerkleRoot());
        token.openClaims(~uint256(0));

        for (uint256 i = 0; i < 10; ++i) {
            vm.startPrank(receivers[i]);
            bytes32[] memory proof = m.getProof(data, i);
            token.whitelistMint(1, proof);

            console.log(token.balanceOf(receivers[i]));

            // assertEq(1, token.balanceOf(receivers[i]));
            // assertEq(token.ownerOf(i + 1), receivers[i]);
            vm.stopPrank();
        }
    }

    function testMintMultipleWhitelists(uint256 length, uint256 salt) public {
        length = bound(length, 2, 20);
        salt = bound(salt, 1, ~uint256(0));

        address[] memory toAddresses = new address[](length);
        bytes32[] memory secondData = new bytes32[](length);
        bytes32 secondRoot;

        for (uint256 i = 0; i < length; ++i) {
            toAddresses[i] = address(uint160(uint256(keccak256(abi.encodePacked(i, salt)))));
            secondData[i] = keccak256(abi.encodePacked(toAddresses[i], uint256(1)));
        }

        secondRoot = m.getRoot(secondData);

        token.setMerkleRoot(root);
        token.openClaims(~uint256(0));

        uint256 tokensMinted;
        bytes32[] memory proof;

        for (uint256 i = 0; i < 9; ++i) {
            vm.startPrank(receivers[i]);
            proof = m.getProof(data, i);
            token.whitelistMint(1, proof);
            tokensMinted++;

            assertEq(1, token.balanceOf(receivers[i]));
            assertEq(token.ownerOf(tokensMinted), receivers[i]);
            vm.stopPrank();
        }

        vm.startPrank(toAddresses[0]);
        proof = m.getProof(secondData, 0);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();

        token.setMerkleRoot(secondRoot);

        for (uint256 i = 0; i < length; ++i) {
            vm.startPrank(toAddresses[i]);
            proof = m.getProof(secondData, i);
            token.whitelistMint(1, proof);
            tokensMinted++;

            assertEq(1, token.balanceOf(toAddresses[i]));
            assertEq(token.ownerOf(tokensMinted), toAddresses[i]);
            vm.stopPrank();
        }

        vm.startPrank(receivers[9]);
        proof = m.getProof(data, 9);
        vm.expectRevert(MerkleWhitelistMintBase.MerkleWhitelistMint__InvalidProof.selector);
        token.whitelistMint(1, proof);
        vm.stopPrank();
    }

    function testSetMerkleRootNotOwner(address nonOwner) public {
        vm.assume(nonOwner != token.owner());
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        token.setMerkleRoot(bytes32(0));
        vm.stopPrank();
    }
}
