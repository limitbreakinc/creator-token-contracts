// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "../mocks/ERC20Mock.sol";
import "contracts/examples/erc721c/ERC721CWithMinterCreatorSharedRoyalties.sol";

contract ERC721CWithMinterCreatorSharedRoyaltiesTest is CreatorTokenTransferValidatorERC721Test {

    ERC20Mock public coinMock;
    ERC721CWithMinterCreatorSharedRoyalties public tokenMock;
    uint256 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    address public defaultTokenCreator;

    function setUp() public virtual override {
        super.setUp();
        
        defaultTokenCreator = address(0x1);

        coinMock = new ERC20Mock(18);

        vm.startPrank(defaultTokenCreator);
        tokenMock = new ERC721CWithMinterCreatorSharedRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, defaultTokenCreator, "Test", "TEST");
        tokenMock.setToCustomSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
        vm.stopPrank();
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(address(new ERC721CWithMinterCreatorSharedRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, creator, "Test", "TEST")));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        ERC721CWithMinterCreatorSharedRoyalties(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        ERC721CWithMinterCreatorSharedRoyalties(tokenAddress).safeMint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(uint256 royaltyFeeNumerator, uint256 minterShares, uint256 creatorShares, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, minterShares, creatorShares, creator, "Test", "TEST");
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());
        vm.assume(minter.balance == 0);
        vm.assume(coinMock.balanceOf(minter) == 0);
        vm.assume(defaultTokenCreator.balance == 0);
        vm.assume(coinMock.balanceOf(defaultTokenCreator) == 0);

        _mintToken(address(tokenMock), minter, tokenId);

        address paymentSplitterOfToken = tokenMock.paymentSplitterOf(tokenId);
        address[] memory paymentSplittersOfMinter = tokenMock.paymentSplittersOfMinter(minter);

        vm.assume(minter != paymentSplitterOfToken);
        vm.assume(defaultTokenCreator != paymentSplitterOfToken);

        vm.deal(paymentSplitterOfToken, 1 ether);
        coinMock.mint(paymentSplitterOfToken, 1 ether);

        assertEq(tokenMock.minterOf(tokenId), minter);
        assertEq(paymentSplittersOfMinter.length, 1);
        assertEq(paymentSplittersOfMinter[0], paymentSplitterOfToken);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, paymentSplitterOfToken);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

        PaymentSplitter splitter = PaymentSplitter(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(address minter, address secondaryOwner, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        _sanitizeAddress(secondaryOwner);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());
        vm.assume(minter.balance == 0);
        vm.assume(coinMock.balanceOf(minter) == 0);
        vm.assume(defaultTokenCreator.balance == 0);
        vm.assume(coinMock.balanceOf(defaultTokenCreator) == 0);

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        address paymentSplitterOfToken = tokenMock.paymentSplitterOf(tokenId);
        address[] memory paymentSplittersOfMinter = tokenMock.paymentSplittersOfMinter(minter);

        vm.assume(minter != paymentSplitterOfToken);
        vm.assume(defaultTokenCreator != paymentSplitterOfToken);

        vm.deal(paymentSplitterOfToken, 1 ether);
        coinMock.mint(paymentSplitterOfToken, 1 ether);

        assertEq(tokenMock.minterOf(tokenId), minter);
        assertEq(paymentSplittersOfMinter.length, 1);
        assertEq(paymentSplittersOfMinter[0], paymentSplitterOfToken);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, paymentSplitterOfToken);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

        PaymentSplitter splitter = PaymentSplitter(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(address minter, address secondaryOwner, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        _sanitizeAddress(secondaryOwner);
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        tokenMock.burn(tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRevertsIfTokenIdMintedAgain(address minter, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId.selector);
        _mintToken(address(tokenMock), minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(address minter, address secondaryOwner, address reminter, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        _sanitizeAddress(secondaryOwner);
        _sanitizeAddress(reminter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);
        vm.assume(secondaryOwner != address(0));
        vm.assume(reminter != address(0));
        vm.assume(reminter.code.length == 0);
        vm.assume(reminter != defaultTokenCreator);
        vm.assume(minter != reminter);
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());
        vm.assume(minter.balance == 0);
        vm.assume(coinMock.balanceOf(minter) == 0);
        vm.assume(reminter.balance == 0);
        vm.assume(coinMock.balanceOf(reminter) == 0);
        vm.assume(defaultTokenCreator.balance == 0);
        vm.assume(coinMock.balanceOf(defaultTokenCreator) == 0);

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        tokenMock.burn(tokenId);

        _mintToken(address(tokenMock), reminter, tokenId);

        address paymentSplitterOfToken = tokenMock.paymentSplitterOf(tokenId);
        address[] memory paymentSplittersOfMinter = tokenMock.paymentSplittersOfMinter(reminter);

        vm.assume(reminter != paymentSplitterOfToken);
        vm.assume(defaultTokenCreator != paymentSplitterOfToken);

        vm.deal(paymentSplitterOfToken, 1 ether);
        coinMock.mint(paymentSplitterOfToken, 1 ether);

        assertEq(tokenMock.minterOf(tokenId), reminter);
        assertEq(paymentSplittersOfMinter.length, 1);
        assertEq(paymentSplittersOfMinter[0], paymentSplitterOfToken);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, paymentSplitterOfToken);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

        PaymentSplitter splitter = PaymentSplitter(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(reminter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(reminter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(reminter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());
        vm.assume(minter.balance == 0);
        vm.assume(coinMock.balanceOf(minter) == 0);
        vm.assume(defaultTokenCreator.balance == 0);
        vm.assume(coinMock.balanceOf(defaultTokenCreator) == 0);

        _safeMintToken(address(tokenMock), minter, tokenId);

        address paymentSplitterOfToken = tokenMock.paymentSplitterOf(tokenId);
        address[] memory paymentSplittersOfMinter = tokenMock.paymentSplittersOfMinter(minter);

        vm.assume(minter != paymentSplitterOfToken);
        vm.assume(defaultTokenCreator != paymentSplitterOfToken);

        vm.deal(paymentSplitterOfToken, 1 ether);
        coinMock.mint(paymentSplitterOfToken, 1 ether);

        assertEq(tokenMock.minterOf(tokenId), minter);
        assertEq(paymentSplittersOfMinter.length, 1);
        assertEq(paymentSplittersOfMinter[0], paymentSplitterOfToken);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, paymentSplitterOfToken);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

        PaymentSplitter splitter = PaymentSplitter(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter), 0.25 ether);
        assertEq(tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator), 0.75 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRevertsWhenQueryingReleasableFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
    }

    function testRevertsWhenReleasingFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Minter);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyalties.ReleaseTo.Creator);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Minter);

        vm.expectRevert(MinterCreatorSharedRoyalties.MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId.selector);
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyalties.ReleaseTo.Creator);
    }
}