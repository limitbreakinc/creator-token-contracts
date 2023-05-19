// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../mocks/minting/ClaimableHolderMintMock.sol";
import "../mocks/ClonerMock.sol";
import "../mocks/ERC721Mock.sol";
import "../mocks/ERC1155Mock.sol";
import "./MaxSupply.t.sol";
import "./ClaimPeriod.t.sol";

contract ClaimableHolderMintConstructableTest is MaxSupplyTest, ClaimPeriodTest {
    ClaimableHolderMintMock token;

    ERC721Mock rootCollection1;
    ERC721Mock rootCollection2;

    function _deployNewToken(address creator)
        internal
        virtual
        override(ClaimPeriodTest, MaxSupplyTest)
        returns (ITestCreatorMintableToken)
    {
        rootCollection1 = new ERC721Mock();
        rootCollection2 = new ERC721Mock();

        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        vm.startPrank(creator);
        token = new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);

        token.initializeIneligibleTokens(false, address(rootCollection1), new uint256[](0), new uint256[](0));
        token.initializeIneligibleTokens(true, address(rootCollection2), new uint256[](0), new uint256[](0));
        vm.stopPrank();
        return ITestCreatorMintableToken(address(token));
    }

    function setUp() public {
        rootCollection1 = new ERC721Mock();
        rootCollection2 = new ERC721Mock();

        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        token = new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);

        token.initializeIneligibleTokens(false, address(rootCollection1), new uint256[](0), new uint256[](0));
        token.initializeIneligibleTokens(true, address(rootCollection2), new uint256[](0), new uint256[](0));
    }

    function testDeployMismatchArray() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](1);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InputArrayLengthMismatch.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployNoRootCollection() public {
        address[] memory rootCollections = new address[](0);
        uint256[] memory maxSupplies = new uint256[](0);
        uint256[] memory tokensPerClaim = new uint256[](0);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__MustSpecifyAtLeastOneRootCollection.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployMoreThanMaxRootCollections() public {
        address[] memory rootCollections = new address[](26);
        uint256[] memory maxSupplies = new uint256[](26);
        uint256[] memory tokensPerClaim = new uint256[](26);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__MaxNumberOfRootCollectionsExceeded.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployNotERC721RootCollection() public {
        ERC1155Mock badToken = new ERC1155Mock();

        address[] memory rootCollections = new address[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory tokensPerClaim = new uint256[](1);

        rootCollections[0] = address(badToken);
        maxSupplies[0] = 10000;
        tokensPerClaim[0] = 1;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__CollectionAddressIsNotAnERC721Token.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployZeroTokensPerClaim() public {
        address[] memory rootCollections = new address[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory tokensPerClaim = new uint256[](1);

        rootCollections[0] = address(rootCollection1);
        maxSupplies[0] = 10000;
        tokensPerClaim[0] = 0;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokensPerClaimMustBeBetweenOneAndTen.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployMoreThanTenTokensPerClaim() public {
        address[] memory rootCollections = new address[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory tokensPerClaim = new uint256[](1);

        rootCollections[0] = address(rootCollection1);
        maxSupplies[0] = 10000;
        tokensPerClaim[0] = 11;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokensPerClaimMustBeBetweenOneAndTen.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testDeployZeroMaxSupply() public {
        address[] memory rootCollections = new address[](1);
        uint256[] memory maxSupplies = new uint256[](1);
        uint256[] memory tokensPerClaim = new uint256[](1);

        rootCollections[0] = address(rootCollection1);
        maxSupplies[0] = 0;
        tokensPerClaim[0] = 2;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__MaxSupplyOfRootTokenCannotBeZero.selector);
        new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);
    }

    function testGetTokensPerClaim() public {
        assertEq(token.getTokensPerClaim(address(rootCollection1)), 1);
        assertEq(token.getTokensPerClaim(address(rootCollection2)), 2);
    }

    function testMintNotOpen() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodIsNotOpen.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testFinalizedIneligibleTokens() public {
        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__IneligibleTokensFinalized.selector);
        token.initializeIneligibleTokens(true, address(rootCollection1), new uint256[](0), new uint256[](0));
    }

    function testMintAlreadyMinted() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        token.claimBatch(address(rootCollection1), tokenIds);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokenIdAlreadyClaimed.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testMintDoesNotOwnToken() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);
        rootCollection2.mint(address(0xdeadbeef), 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__CallerDoesNotOwnRootTokenId.selector);
        token.claimBatch(address(rootCollection2), tokenIds);
    }

    function testMintZeroBatch() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);

        uint256[] memory tokenIds = new uint256[](0);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__BatchSizeMustBeGreaterThanZero.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testMintMoreThanMaxBatch() public {
        token.openClaims(~uint256(0));

        uint256[] memory tokenIds = new uint256[](301);
        for (uint256 i = 0; i < 301; ++i) {
            rootCollection1.mint(address(this), i + 1);
            tokenIds[i] = i + 1;
        }

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__BatchSizeGreaterThanMaximum.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testOpenClaimsIneligibleTokensNotFinalized() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        token = new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__IneligibleTokensHaveNotBeenFinalized.selector);
        token.openClaims(~uint256(0));
    }

    function testSetIneligibleTokensArrayMismatch() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        token = new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InputArrayLengthMismatch.selector);
        token.initializeIneligibleTokens(true, address(rootCollection2), new uint256[](1), new uint256[](0));
    }

    function testMintIneligibleToken() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        token = new ClaimableHolderMintMock(rootCollections, maxSupplies, tokensPerClaim, 10010, 10);

        uint256[] memory ineligibleSlots1 = new uint256[](5);
        uint256[] memory ineligibleSlots2 = new uint256[](4);
        uint256[] memory ineligibleBitmap1 = new uint256[](5);
        uint256[] memory ineligibleBitmap2 = new uint256[](4);

        ineligibleSlots1[0] = 1;
        ineligibleSlots1[1] = 2;
        ineligibleSlots1[2] = 3;
        ineligibleSlots1[3] = 6;
        ineligibleSlots1[4] = 7;

        ineligibleSlots2[0] = 0;
        ineligibleSlots2[1] = 5;
        ineligibleSlots2[2] = 7;
        ineligibleSlots2[3] = 8;

        ineligibleBitmap1[0] = 10633823966279326983230456482242756608;
        ineligibleBitmap1[1] = 83076749736557242056487941267521536;
        ineligibleBitmap1[2] = 102844034832575377634685573909834406561420991602098741459288064;
        ineligibleBitmap1[3] = 79228162514264337593543950336;
        ineligibleBitmap1[4] = 89202980794122492566142873090593446023921664;

        ineligibleBitmap2[0] = 309485009821345068724781056;
        ineligibleBitmap2[1] = 8;
        ineligibleBitmap2[2] = 28269553036479860282040903856295367646717200951650258577846223906046738432;
        ineligibleBitmap2[3] = 4951760157141521099596496896;

        token.initializeIneligibleTokens(false, address(rootCollection1), ineligibleSlots1, ineligibleBitmap1);
        token.initializeIneligibleTokens(true, address(rootCollection2), ineligibleSlots2, ineligibleBitmap2);

        token.openClaims(~uint256(0));

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 379;

        rootCollection1.mint(address(this), tokenIds[0]);

        assertFalse(token.isEligible(address(rootCollection1), tokenIds[0]));

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokenIdAlreadyClaimed.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testComputeIneligibleTokensBitmapZeroLength() public {
        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__MustSpecifyAtLeastOneIneligibleToken.selector);
        token.computeIneligibleTokensBitmap(new uint256[](0));
    }

    function testComputeIneligibleTokensBitmapNonAscending() public {
        uint256[] memory ineligibleTokens = new uint256[](5);
        ineligibleTokens[0] = 1;
        ineligibleTokens[1] = 2;
        ineligibleTokens[2] = 3;
        ineligibleTokens[3] = 6;
        ineligibleTokens[4] = 5;

        vm.expectRevert(
            ClaimableHolderMintBase.ClaimableHolderMint__IneligibleTokenArrayMustBeInAscendingOrder.selector
        );
        token.computeIneligibleTokensBitmap(ineligibleTokens);
    }

    function testComputeIneligibleTokensBitmap() public {
        uint256[] memory ineligibleTokens = new uint256[](1);
        ineligibleTokens[0] = 1;

        (uint256[] memory slots, uint256[] memory bitmap) = token.computeIneligibleTokensBitmap(ineligibleTokens);
        assertEq(slots[0], 0);
        assertEq(bitmap[0], 2);
    }

    function testIsEligibleInvalidTokenId(uint256 tokenId) public {
        vm.assume(tokenId > 10000);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InvalidRootCollectionTokenId.selector);
        token.isEligible(address(rootCollection1), tokenId);
    }

    function testIsClaimedInvalidTokenId(uint256 tokenId) public {
        vm.assume(tokenId > 10000);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InvalidRootCollectionTokenId.selector);
        token.isClaimed(address(rootCollection1), tokenId);
    }

    function testHolderMints(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);

        token.openClaims(~uint256(0));

        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            rootCollection1.mint(receivers[i], i + 1);
            rootCollection2.mint(receivers[i], i + 1);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = i + 1;

            vm.startPrank(receivers[i]);
            token.claimBatch(address(rootCollection1), tokenIds);
            token.claimBatch(address(rootCollection2), tokenIds);
            assert(token.isClaimed(address(rootCollection1), tokenIds[0]));
            assert(token.isClaimed(address(rootCollection2), tokenIds[0]));
            vm.stopPrank();
            ++nonce;
        }

        uint256 tokenID = 1;
        for (uint256 i = 0; i < 100; ++i) {
            assertEq(token.ownerOf(tokenID), receivers[i]);
            assertEq(token.ownerOf(tokenID + 1), receivers[i]);
            assertEq(token.ownerOf(tokenID + 2), receivers[i]);
            tokenID += 3;
            assertEq(token.balanceOf(receivers[i]), 3);
        }
    }
}

contract ClaimableHolderMintInitializableTest is MaxSupplyInitializableTest, ClaimPeriodTest {
    ClaimableHolderMintInitializableMock token;
    ClaimableHolderMintInitializableMock referenceToken;

    ERC721Mock rootCollection1;
    ERC721Mock rootCollection2;

    function _deployNewToken(address creator)
        internal
        virtual
        override(ClaimPeriodTest, MaxSupplyInitializableTest)
        returns (ITestCreatorMintableToken)
    {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        bytes4[] memory initializationSelectors = new bytes4[](5);
        bytes[] memory initializationArguments = new bytes[](5);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeRootCollections.selector;
        initializationArguments[1] = abi.encode(rootCollections, maxSupplies, tokensPerClaim);

        initializationSelectors[2] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[2] = abi.encode(false, rootCollections[0], new uint256[](0), new uint256[](0));

        initializationSelectors[3] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[3] = abi.encode(true, rootCollections[1], new uint256[](0), new uint256[](0));

        initializationSelectors[4] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[4] = abi.encode(110, 10);

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
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        bytes4[] memory initializationSelectors = new bytes4[](4);
        bytes[] memory initializationArguments = new bytes[](4);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeRootCollections.selector;
        initializationArguments[1] = abi.encode(rootCollections, maxSupplies, tokensPerClaim);

        initializationSelectors[2] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[2] = abi.encode(false, rootCollections[0], new uint256[](0), new uint256[](0));

        initializationSelectors[3] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[3] = abi.encode(true, rootCollections[1], new uint256[](0), new uint256[](0));

        return ITestCreatorMintableToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function setUp() public override {
        super.setUp();
        referenceToken = new ClaimableHolderMintInitializableMock();

        rootCollection1 = new ERC721Mock();
        rootCollection2 = new ERC721Mock();

        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        bytes4[] memory initializationSelectors = new bytes4[](5);
        bytes[] memory initializationArguments = new bytes[](5);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeRootCollections.selector;
        initializationArguments[1] = abi.encode(rootCollections, maxSupplies, tokensPerClaim);

        initializationSelectors[2] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[2] = abi.encode(false, rootCollections[0], new uint256[](0), new uint256[](0));

        initializationSelectors[3] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[3] = abi.encode(true, rootCollections[1], new uint256[](0), new uint256[](0));

        initializationSelectors[4] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[4] = abi.encode(10000, 10);

        token = ClaimableHolderMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
    }

    function testInitializeAlreadyInitialized() public {
        vm.expectRevert(
            ClaimableHolderMintInitializable
                .ClaimableHolderMintInitializable__RootCollectionsAlreadyInitialized
                .selector
        );
        token.initializeRootCollections(new address[](1), new uint256[](1), new uint256[](1));
    }

    function testGetTokensPerClaim() public {
        assertEq(token.getTokensPerClaim(address(rootCollection1)), 1);
        assertEq(token.getTokensPerClaim(address(rootCollection2)), 2);
    }

    function testMintNotOpen() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodIsNotOpen.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testFinalizedIneligibleTokens() public {
        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__IneligibleTokensFinalized.selector);
        token.initializeIneligibleTokens(true, address(rootCollection1), new uint256[](0), new uint256[](0));
    }

    function testMintAlreadyMinted() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        token.claimBatch(address(rootCollection1), tokenIds);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokenIdAlreadyClaimed.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testMintDoesNotOwnToken() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);
        rootCollection2.mint(address(0xdeadbeef), 1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__CallerDoesNotOwnRootTokenId.selector);
        token.claimBatch(address(rootCollection2), tokenIds);
    }

    function testMintZeroBatch() public {
        token.openClaims(~uint256(0));

        rootCollection1.mint(address(this), 1);

        uint256[] memory tokenIds = new uint256[](0);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__BatchSizeMustBeGreaterThanZero.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testMintMoreThanMaxBatch() public {
        token.openClaims(~uint256(0));

        uint256[] memory tokenIds = new uint256[](301);
        for (uint256 i = 0; i < 301; ++i) {
            rootCollection1.mint(address(this), i + 1);
            tokenIds[i] = i + 1;
        }

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__BatchSizeGreaterThanMaximum.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testSetIneligibleTokensArrayMismatch() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[1] = abi.encode(false, rootCollections[0], new uint256[](0), new uint256[](0));

        initializationSelectors[2] = referenceToken.initializeIneligibleTokens.selector;
        initializationArguments[2] = abi.encode(true, rootCollections[1], new uint256[](0), new uint256[](1));

        vm.expectRevert(abi.encodeWithSelector(ClonerMock.InitializationArgumentInvalid.selector, 1));
        token = ClaimableHolderMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );
    }

    function testMintIneligibleToken() public {
        address[] memory rootCollections = new address[](2);
        uint256[] memory maxSupplies = new uint256[](2);
        uint256[] memory tokensPerClaim = new uint256[](2);

        rootCollections[0] = address(rootCollection1);
        rootCollections[1] = address(rootCollection2);

        maxSupplies[0] = 10000;
        maxSupplies[1] = 10000;

        tokensPerClaim[0] = 1;
        tokensPerClaim[1] = 2;

        bytes4[] memory initializationSelectors = new bytes4[](3);
        bytes[] memory initializationArguments = new bytes[](3);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeRootCollections.selector;
        initializationArguments[1] = abi.encode(rootCollections, maxSupplies, tokensPerClaim);

        initializationSelectors[2] = referenceToken.initializeMaxSupply.selector;
        initializationArguments[2] = abi.encode(110, 10);

        token = ClaimableHolderMintInitializableMock(
            cloner.cloneContract(
                address(referenceToken), address(this), initializationSelectors, initializationArguments
            )
        );

        uint256[] memory ineligibleSlots1 = new uint256[](5);
        uint256[] memory ineligibleSlots2 = new uint256[](4);
        uint256[] memory ineligibleBitmap1 = new uint256[](5);
        uint256[] memory ineligibleBitmap2 = new uint256[](4);

        ineligibleSlots1[0] = 1;
        ineligibleSlots1[1] = 2;
        ineligibleSlots1[2] = 3;
        ineligibleSlots1[3] = 6;
        ineligibleSlots1[4] = 7;

        ineligibleSlots2[0] = 0;
        ineligibleSlots2[1] = 5;
        ineligibleSlots2[2] = 7;
        ineligibleSlots2[3] = 8;

        ineligibleBitmap1[0] = 10633823966279326983230456482242756608;
        ineligibleBitmap1[1] = 83076749736557242056487941267521536;
        ineligibleBitmap1[2] = 102844034832575377634685573909834406561420991602098741459288064;
        ineligibleBitmap1[3] = 79228162514264337593543950336;
        ineligibleBitmap1[4] = 89202980794122492566142873090593446023921664;

        ineligibleBitmap2[0] = 309485009821345068724781056;
        ineligibleBitmap2[1] = 8;
        ineligibleBitmap2[2] = 28269553036479860282040903856295367646717200951650258577846223906046738432;
        ineligibleBitmap2[3] = 4951760157141521099596496896;

        token.initializeIneligibleTokens(false, address(rootCollection1), ineligibleSlots1, ineligibleBitmap1);
        token.initializeIneligibleTokens(true, address(rootCollection2), ineligibleSlots2, ineligibleBitmap2);

        token.openClaims(~uint256(0));

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 379;

        rootCollection1.mint(address(this), tokenIds[0]);

        assertFalse(token.isEligible(address(rootCollection1), tokenIds[0]));

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__TokenIdAlreadyClaimed.selector);
        token.claimBatch(address(rootCollection1), tokenIds);
    }

    function testComputeIneligibleTokensBitmapZeroLength() public {
        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__MustSpecifyAtLeastOneIneligibleToken.selector);
        token.computeIneligibleTokensBitmap(new uint256[](0));
    }

    function testComputeIneligibleTokensBitmapNonAscending() public {
        uint256[] memory ineligibleTokens = new uint256[](5);
        ineligibleTokens[0] = 1;
        ineligibleTokens[1] = 2;
        ineligibleTokens[2] = 3;
        ineligibleTokens[3] = 6;
        ineligibleTokens[4] = 5;

        vm.expectRevert(
            ClaimableHolderMintBase.ClaimableHolderMint__IneligibleTokenArrayMustBeInAscendingOrder.selector
        );
        token.computeIneligibleTokensBitmap(ineligibleTokens);
    }

    function testComputeIneligibleTokensBitmap() public {
        uint256[] memory ineligibleTokens = new uint256[](1);
        ineligibleTokens[0] = 1;

        (uint256[] memory slots, uint256[] memory bitmap) = token.computeIneligibleTokensBitmap(ineligibleTokens);
        assertEq(slots[0], 0);
        assertEq(bitmap[0], 2);
    }

    function testIsEligibleInvalidTokenId(uint256 tokenId) public {
        vm.assume(tokenId > 10000);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InvalidRootCollectionTokenId.selector);
        token.isEligible(address(rootCollection1), tokenId);
    }

    function testIsClaimedInvalidTokenId(uint256 tokenId) public {
        vm.assume(tokenId > 10000);

        vm.expectRevert(ClaimableHolderMintBase.ClaimableHolderMint__InvalidRootCollectionTokenId.selector);
        token.isClaimed(address(rootCollection1), tokenId);
    }

    function testHolderMints(uint256 nonce, bytes32 sample) public {
        nonce = bound(nonce, 1, 999999999999999999);
        address[] memory receivers = new address[](100);

        token.openClaims(~uint256(0));

        for (uint256 i = 0; i < 100; ++i) {
            receivers[i] = address(uint160(uint256(keccak256(abi.encodePacked(nonce, sample)))));
            rootCollection1.mint(receivers[i], i + 1);
            rootCollection2.mint(receivers[i], i + 1);
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = i + 1;

            vm.startPrank(receivers[i]);
            token.claimBatch(address(rootCollection1), tokenIds);
            token.claimBatch(address(rootCollection2), tokenIds);
            assert(token.isClaimed(address(rootCollection1), tokenIds[0]));
            assert(token.isClaimed(address(rootCollection2), tokenIds[0]));
            vm.stopPrank();
            ++nonce;
        }

        uint256 tokenID = 1;
        for (uint256 i = 0; i < 100; ++i) {
            assertEq(token.ownerOf(tokenID), receivers[i]);
            assertEq(token.ownerOf(tokenID + 1), receivers[i]);
            assertEq(token.ownerOf(tokenID + 2), receivers[i]);
            tokenID += 3;
            assertEq(token.balanceOf(receivers[i]), 3);
        }
    }
}
