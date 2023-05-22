// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../mocks/ClonerMock.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "contracts/examples/erc721c/ERC721CWithMutableMinterRoyalties.sol";

contract ERC721CWithMutableMinterRoyaltiesTest is CreatorTokenTransferValidatorERC721Test {
    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    ERC721CWithMutableMinterRoyalties public tokenMock;
    uint96 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    function setUp() public virtual override {
        super.setUp();

        tokenMock = new ERC721CWithMutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST");
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(
            address(new ERC721CWithMutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST"))
        );
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        uint96 defaultRoyaltyFee = ERC721CWithMutableMinterRoyalties(tokenAddress).defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        ERC721CWithMutableMinterRoyalties(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        uint96 defaultRoyaltyFee = ERC721CWithMutableMinterRoyalties(tokenAddress).defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        ERC721CWithMutableMinterRoyalties(tokenAddress).safeMint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(uint96 royaltyFeeNumerator) public {
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        new ERC721CWithMutableMinterRoyalties(royaltyFeeNumerator, "Test", "TEST");
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        uint96 defaultRoyaltyFee = tokenMock.defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFee);
        tokenMock.burn(tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRevertsIfTokenIdMintedAgain(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(
            MutableMinterRoyaltiesBase.MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId.selector
        );
        tokenMock.mint(minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(
        address minter,
        address secondaryOwner,
        address reminter,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(reminter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        uint96 defaultRoyaltyFee = tokenMock.defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFee);
        tokenMock.burn(tokenId);

        _mintToken(address(tokenMock), reminter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, reminter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testMinterCanSetRoyaltyFee(address minter, uint256 tokenId, uint256 salePrice, uint96 updatedFee) public {
        vm.assume(minter != address(0));
        vm.assume(updatedFee == 0 || salePrice < type(uint256).max / updatedFee);
        vm.assume(updatedFee <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, minter, updatedFee);
        tokenMock.setRoyaltyFee(tokenId, updatedFee);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);

        assertEq(recipient, minter);
        assertEq(value, (salePrice * updatedFee) / tokenMock.FEE_DENOMINATOR());
    }

    function testRevertsWhenMinterSetsFeeNumeratorToExceedSalesPrice(
        address minter,
        uint256 tokenId,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
    }

    function testRevertsWhenUnauthorizedUserAttemptsToSetRoyaltyFee(
        address minter,
        address unauthorizedUser,
        uint256 tokenId,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(minter != unauthorizedUser);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
    }

    function testRevertsWhenMinterAttemptsToSetRoyaltyFeeForAnotherMintersTokenId(
        address minter,
        address minter2,
        uint256 tokenId,
        uint256 tokenIdMinter2,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(minter2 != address(0));
        vm.assume(minter != minter2);
        vm.assume(tokenId != tokenIdMinter2);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        _mintToken(address(tokenMock), minter2, tokenIdMinter2);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter2);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter);
        tokenMock.setRoyaltyFee(tokenIdMinter2, royaltyFeeNumerator);
    }

    function testRevertsWhenMinterAttemptsToSetRoyaltyFeeForAnUnmintedTokenId(
        address minter,
        uint256 tokenId,
        uint256 tokenIdUnminted,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(tokenId != tokenIdUnminted);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter);
        tokenMock.setRoyaltyFee(tokenIdUnminted, royaltyFeeNumerator);
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _safeMintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }
}

contract ERC721CWithMutableMinterRoyaltiesInitializableTest is CreatorTokenTransferValidatorERC721Test {
    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    ClonerMock cloner;

    ERC721CWithMutableMinterRoyaltiesInitializable public referenceToken;
    ERC721CWithMutableMinterRoyaltiesInitializable public tokenMock;
    uint96 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    function setUp() public virtual override {
        super.setUp();

        cloner = new ClonerMock();
        referenceToken = new ERC721CWithMutableMinterRoyaltiesInitializable();

        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeDefaultMinterRoyaltyFee.selector;
        initializationArguments[1] = abi.encode(DEFAULT_ROYALTY_FEE_NUMERATOR);

        tokenMock = ERC721CWithMutableMinterRoyaltiesInitializable(
            cloner.cloneContract(address(referenceToken), address(this), initializationSelectors, initializationArguments)
        );
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeDefaultMinterRoyaltyFee.selector;
        initializationArguments[1] = abi.encode(DEFAULT_ROYALTY_FEE_NUMERATOR);
        return ITestCreatorToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function _deployUninitializedToken() internal returns (ERC721CWithMutableMinterRoyaltiesInitializable) {
        return ERC721CWithMutableMinterRoyaltiesInitializable(
            cloner.cloneContract(address(referenceToken), address(this), new bytes4[](0), new bytes[](0))
        );
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        uint96 defaultRoyaltyFee = ERC721CWithMutableMinterRoyaltiesInitializable(tokenAddress).defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        ERC721CWithMutableMinterRoyaltiesInitializable(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        uint96 defaultRoyaltyFee = ERC721CWithMutableMinterRoyaltiesInitializable(tokenAddress).defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        ERC721CWithMutableMinterRoyaltiesInitializable(tokenAddress).safeMint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(uint96 royaltyFeeNumerator) public {
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        ERC721CWithMutableMinterRoyaltiesInitializable token = _deployUninitializedToken();
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        token.initializeDefaultMinterRoyaltyFee(royaltyFeeNumerator);
    }

    function testInitializeAlreadyInitialized() public {
        vm.expectRevert(MutableMinterRoyaltiesInitializable.MutableMinterRoyaltiesInitializable__DefaultMinterRoyaltyFeeAlreadyInitialized.selector);
        tokenMock.initializeDefaultMinterRoyaltyFee(1000);
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        uint96 defaultRoyaltyFee = tokenMock.defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFee);
        tokenMock.burn(tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRevertsIfTokenIdMintedAgain(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(
            MutableMinterRoyaltiesBase.MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId.selector
        );
        tokenMock.mint(minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(
        address minter,
        address secondaryOwner,
        address reminter,
        uint256 tokenId,
        uint256 salePrice
    ) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(reminter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        uint96 defaultRoyaltyFee = tokenMock.defaultRoyaltyFeeNumerator();
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFee);
        tokenMock.burn(tokenId);

        _mintToken(address(tokenMock), reminter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, reminter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testMinterCanSetRoyaltyFee(address minter, uint256 tokenId, uint256 salePrice, uint96 updatedFee) public {
        vm.assume(minter != address(0));
        vm.assume(updatedFee == 0 || salePrice < type(uint256).max / updatedFee);
        vm.assume(updatedFee <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        vm.expectEmit(true, true, false, true);
        emit RoyaltySet(tokenId, minter, updatedFee);
        tokenMock.setRoyaltyFee(tokenId, updatedFee);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);

        assertEq(recipient, minter);
        assertEq(value, (salePrice * updatedFee) / tokenMock.FEE_DENOMINATOR());
    }

    function testRevertsWhenMinterSetsFeeNumeratorToExceedSalesPrice(
        address minter,
        uint256 tokenId,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
    }

    function testRevertsWhenUnauthorizedUserAttemptsToSetRoyaltyFee(
        address minter,
        address unauthorizedUser,
        uint256 tokenId,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(minter != unauthorizedUser);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
    }

    function testRevertsWhenMinterAttemptsToSetRoyaltyFeeForAnotherMintersTokenId(
        address minter,
        address minter2,
        uint256 tokenId,
        uint256 tokenIdMinter2,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(minter2 != address(0));
        vm.assume(minter != minter2);
        vm.assume(tokenId != tokenIdMinter2);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);
        _mintToken(address(tokenMock), minter2, tokenIdMinter2);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter2);
        tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter);
        tokenMock.setRoyaltyFee(tokenIdMinter2, royaltyFeeNumerator);
    }

    function testRevertsWhenMinterAttemptsToSetRoyaltyFeeForAnUnmintedTokenId(
        address minter,
        uint256 tokenId,
        uint256 tokenIdUnminted,
        uint96 royaltyFeeNumerator
    ) public {
        vm.assume(minter != address(0));
        vm.assume(tokenId != tokenIdUnminted);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(MutableMinterRoyaltiesBase.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
        vm.prank(minter);
        tokenMock.setRoyaltyFee(tokenIdUnminted, royaltyFeeNumerator);
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        _safeMintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }
}