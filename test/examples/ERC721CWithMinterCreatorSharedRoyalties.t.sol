// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "../mocks/ERC20Mock.sol";
import "../mocks/ClonerMock.sol";
import "contracts/examples/erc721c/ERC721CWithMinterCreatorSharedRoyalties.sol";
import "contracts/programmable-royalties/helpers/PaymentSplitterInitializable.sol";

contract ERC721CWithMinterCreatorSharedRoyaltiesConstructableTest is CreatorTokenTransferValidatorERC721Test {
    ERC20Mock public coinMock;
    ERC721CWithMinterCreatorSharedRoyalties public tokenMock;
    uint256 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    address public defaultTokenCreator;
    address paymentSplitterReference;

    function setUp() public virtual override {
        super.setUp();

        defaultTokenCreator = address(0x1);

        coinMock = new ERC20Mock(18);

        paymentSplitterReference = address(new PaymentSplitterInitializable());

        vm.startPrank(defaultTokenCreator);
        tokenMock =
        new ERC721CWithMinterCreatorSharedRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, defaultTokenCreator, paymentSplitterReference, "Test", "TEST");
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
        vm.stopPrank();
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(
            address(
                new ERC721CWithMinterCreatorSharedRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, creator, paymentSplitterReference, "Test", "TEST")
            )
        );
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

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice.selector
        );
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, minterShares, creatorShares, creator, paymentSplitterReference, "Test", "TEST");
    }

    function testRevertsWhenMinterSharesAreZero(
        uint256 royaltyFeeNumerator,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__MinterSharesCannotBeZero.selector
        );
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, 0, creatorShares, creator, paymentSplitterReference, "Test", "TEST");
    }

    function testRevertsWhenCreatorSharesAreZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__CreatorSharesCannotBeZero.selector
        );
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, minterShares, 0, creator, paymentSplitterReference, "Test", "TEST");
    }

    function testRevertsWhenCreatorIsAddressZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares
    ) public {
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__CreatorCannotBeZeroAddress.selector
        );
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, minterShares, creatorShares, address(0), paymentSplitterReference, "Test", "TEST");
    }

    function testRevertsWhenSplitterReferenceIsAddressZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__PaymentSplitterReferenceCannotBeZeroAddress.selector
        );
        new ERC721CWithMinterCreatorSharedRoyalties(royaltyFeeNumerator, minterShares, creatorShares, creator, address(0), "Test", "TEST");
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId
                .selector
        );
        _mintToken(address(tokenMock), minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(
        address minter,
        address secondaryOwner,
        address reminter,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(reminter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(reminter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(reminter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRevertsWhenQueryingReleasableFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
    }

    function testRevertsWhenReleasingFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
    }
}

contract ERC721CWithMinterCreatorSharedRoyaltiesInitializableTest is CreatorTokenTransferValidatorERC721Test {

    ClonerMock cloner;

    ERC20Mock public coinMock;
    ERC721CWithMinterCreatorSharedRoyaltiesInitializable public referenceToken;
    ERC721CWithMinterCreatorSharedRoyaltiesInitializable public tokenMock;
    uint256 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    address public defaultTokenCreator;
    address paymentSplitterReference;

    function setUp() public virtual override {
        super.setUp();

        defaultTokenCreator = address(0x1);

        coinMock = new ERC20Mock(18);

        paymentSplitterReference = address(new PaymentSplitterInitializable());
        cloner = new ClonerMock();
        referenceToken = new ERC721CWithMinterCreatorSharedRoyaltiesInitializable();

        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMinterRoyaltyFee.selector;
        initializationArguments[1] = abi.encode(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, defaultTokenCreator, paymentSplitterReference);

        tokenMock = ERC721CWithMinterCreatorSharedRoyaltiesInitializable(
            cloner.cloneContract(address(referenceToken), defaultTokenCreator, initializationSelectors, initializationArguments)
        );
        vm.prank(defaultTokenCreator);
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMinterRoyaltyFee.selector;
        initializationArguments[1] = abi.encode(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, defaultTokenCreator, paymentSplitterReference);

        return ITestCreatorToken(
            cloner.cloneContract(address(referenceToken), creator, initializationSelectors, initializationArguments)
        );
    }

    function _deployUninitializedToken(address creator) internal returns (ERC721CWithMinterCreatorSharedRoyaltiesInitializable) {
        return ERC721CWithMinterCreatorSharedRoyaltiesInitializable(cloner.cloneContract(address(referenceToken), creator, new bytes4[](0), new bytes[](0)));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        ERC721CWithMinterCreatorSharedRoyalties(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        ERC721CWithMinterCreatorSharedRoyalties(tokenAddress).safeMint(to, tokenId);
    }

    function testInitializeAlreadyInitialized() public {
        vm.prank(defaultTokenCreator);
        vm.expectRevert(MinterCreatorSharedRoyaltiesInitializable.MinterCreatorSharedRoyaltiesInitializable__RoyaltyFeeAndSharesAlreadyInitialized.selector);
        tokenMock.initializeMinterRoyaltyFee(DEFAULT_ROYALTY_FEE_NUMERATOR, 25, 75, defaultTokenCreator, paymentSplitterReference);
    }

    function testRevertsWhenMinterSharesAreZero(
        uint256 royaltyFeeNumerator,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        tokenMock = _deployUninitializedToken(creator);
        vm.prank(creator);
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__MinterSharesCannotBeZero.selector
        );
        tokenMock.initializeMinterRoyaltyFee(royaltyFeeNumerator, 0, creatorShares, creator, paymentSplitterReference);
    }

    function testRevertsWhenCreatorSharesAreZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());

        tokenMock = _deployUninitializedToken(creator);
        vm.prank(creator);
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__CreatorSharesCannotBeZero.selector
        );
        tokenMock.initializeMinterRoyaltyFee(royaltyFeeNumerator, minterShares, 0, creator, paymentSplitterReference);
    }

    function testRevertsWhenCreatorIsAddressZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        tokenMock = _deployUninitializedToken(creator);
        vm.prank(creator);
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__CreatorCannotBeZeroAddress.selector
        );
        tokenMock.initializeMinterRoyaltyFee(royaltyFeeNumerator, minterShares, creatorShares, address(0), paymentSplitterReference);
    }

    function testRevertsWhenSplitterReferenceIsAddressZero(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(royaltyFeeNumerator < tokenMock.FEE_DENOMINATOR());
        tokenMock = _deployUninitializedToken(creator);
        vm.prank(creator);
        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase.MinterCreatorSharedRoyalties__PaymentSplitterReferenceCannotBeZeroAddress.selector
        );
        tokenMock.initializeMinterRoyaltyFee(royaltyFeeNumerator, minterShares, creatorShares, creator, address(0));
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(
        uint256 royaltyFeeNumerator,
        uint256 minterShares,
        uint256 creatorShares,
        address creator
    ) public {
        vm.assume(creator != address(0));
        vm.assume(minterShares > 0 && minterShares < 10000);
        vm.assume(creatorShares > 0 && creatorShares < 10000);
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        bytes4[] memory initializationSelectors = new bytes4[](2);
        bytes[] memory initializationArguments = new bytes[](2);

        initializationSelectors[0] = referenceToken.initializeERC721.selector;
        initializationArguments[0] = abi.encode("Test", "TST");

        initializationSelectors[1] = referenceToken.initializeMinterRoyaltyFee.selector;
        initializationArguments[1] = abi.encode(royaltyFeeNumerator, minterShares, creatorShares, creator, paymentSplitterReference);
        vm.expectRevert(abi.encodeWithSelector(ClonerMock.InitializationArgumentInvalid.selector, 1));
        ERC721CWithMinterCreatorSharedRoyaltiesInitializable(
            cloner.cloneContract(address(referenceToken), address(this), initializationSelectors, initializationArguments)
        );
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testCreatePaymentSplitterSameMinterAndCreator(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());
        vm.assume(defaultTokenCreator.balance == 0);
        vm.assume(coinMock.balanceOf(defaultTokenCreator) == 0);

        _mintToken(address(tokenMock), defaultTokenCreator, tokenId);

        address paymentSplitterOfToken = tokenMock.paymentSplitterOf(tokenId);
        address[] memory paymentSplittersOfMinter = tokenMock.paymentSplittersOfMinter(defaultTokenCreator);

        vm.assume(defaultTokenCreator != paymentSplitterOfToken);

        vm.deal(paymentSplitterOfToken, 1 ether);
        coinMock.mint(paymentSplitterOfToken, 1 ether);

        assertEq(tokenMock.minterOf(tokenId), defaultTokenCreator);
        assertEq(paymentSplittersOfMinter.length, 1);
        assertEq(paymentSplittersOfMinter[0], paymentSplitterOfToken);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, paymentSplitterOfToken);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(creatorShares, 100);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 1 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            1 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 1 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 1 ether);
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(
        address minter,
        address secondaryOwner,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId
                .selector
        );
        _mintToken(address(tokenMock), minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(
        address minter,
        address secondaryOwner,
        address reminter,
        uint256 tokenId,
        uint256 salePrice
    ) public {
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(reminter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(reminter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(reminter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
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

        PaymentSplitterInitializable splitter = PaymentSplitterInitializable(payable(paymentSplitterOfToken));

        uint256 minterShares = splitter.shares(minter);
        uint256 creatorShares = splitter.shares(defaultTokenCreator);

        assertEq(minterShares, 25);
        assertEq(creatorShares, 75);

        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter), 0.25 ether
        );
        assertEq(
            tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator), 0.75 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter
            ),
            0.25 ether
        );
        assertEq(
            tokenMock.releasableERC20Funds(
                tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator
            ),
            0.75 ether
        );

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(minter.balance, 0.25 ether);

        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(defaultTokenCreator.balance, 0.75 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);
        assertEq(coinMock.balanceOf(minter), 0.25 ether);

        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
        assertEq(coinMock.balanceOf(defaultTokenCreator), 0.75 ether);
    }

    function testRevertsWhenQueryingReleasableFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releasableERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
    }

    function testRevertsWhenReleasingFundsForNonExistentTokenId(address minter, uint256 tokenId) public {
        _sanitizeAddress(minter);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(minter != defaultTokenCreator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseNativeFunds(tokenId, MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Minter);

        vm.expectRevert(
            MinterCreatorSharedRoyaltiesBase
                .MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId
                .selector
        );
        tokenMock.releaseERC20Funds(tokenId, address(coinMock), MinterCreatorSharedRoyaltiesBase.ReleaseTo.Creator);
    }
}
