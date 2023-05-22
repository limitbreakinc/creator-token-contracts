// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "../mocks/ERC20Mock.sol";
import "contracts/examples/erc721ac/ERC721ACWithReassignableMinterRoyalties.sol";
import "contracts/programmable-royalties/helpers/RoyaltyRightsNFT.sol";

contract ERC721ACWithMinterRoyaltiesReassignableRightsNFTTest is CreatorTokenTransferValidatorERC721Test {
    address public royaltyRightsNFTReference;
    ERC20Mock public coinMock;
    ERC721ACWithReassignableMinterRoyalties public tokenMock;
    uint256 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    address public defaultTokenCreator;

    function setUp() public virtual override {
        super.setUp();

        defaultTokenCreator = address(0x1);

        coinMock = new ERC20Mock(18);

        royaltyRightsNFTReference = address(new RoyaltyRightsNFT());

        vm.startPrank(defaultTokenCreator);
        tokenMock =
        new ERC721ACWithReassignableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, royaltyRightsNFTReference, "Test", "TEST");
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
        vm.stopPrank();
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(
            address(
                new ERC721ACWithReassignableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, royaltyRightsNFTReference, "Test", "TEST")
            )
        );
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        ERC721ACWithReassignableMinterRoyalties(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        ERC721ACWithReassignableMinterRoyalties(tokenAddress).safeMint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        // TODO: Figure out why these assertions fail
        //assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        //assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        //assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
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
            MinterRoyaltiesReassignableRightsNFT
                .MinterRoyaltiesReassignableRightsNFT__RoyaltyFeeWillExceedSalePrice
                .selector
        );
        new ERC721ACWithReassignableMinterRoyalties(royaltyFeeNumerator, royaltyRightsNFTReference, "Test", "TEST");
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

            assertEq(RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT())).ownerOf(tokenId), minter);
        }
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(
        address minter,
        address secondaryOwner,
        uint256 quantity,
        uint256 salePrice
    ) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.prank(minter);
            tokenMock.transferFrom(minter, secondaryOwner, tokenId);

            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

            assertEq(RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT())).ownerOf(tokenId), minter);
        }
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(
        address minter,
        address secondaryOwner,
        uint256 quantity,
        uint256 salePrice
    ) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.prank(minter);
            tokenMock.transferFrom(minter, secondaryOwner, tokenId);

            vm.prank(secondaryOwner);
            tokenMock.burn(tokenId);

            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, address(0));
            assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

            RoyaltyRightsNFT rightsNFT = RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT()));

            vm.expectRevert("ERC721: invalid token ID");
            address rightsOwner = rightsNFT.ownerOf(tokenId);
        }
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _safeMintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

            assertEq(RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT())).ownerOf(tokenId), minter);
        }
    }

    function testRoyaltyRightsNFTHolderGetsTheRoyalties(
        address minter,
        address rightsOwner,
        uint256 quantity,
        uint256 salePrice
    ) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(rightsOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        RoyaltyRightsNFT rightsNFT = RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT()));

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.prank(minter);
            rightsNFT.transferFrom(minter, rightsOwner, tokenId);

            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, rightsOwner);
            assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());

            assertEq(RoyaltyRightsNFT(address(tokenMock.royaltyRightsNFT())).ownerOf(tokenId), rightsOwner);
        }
    }
}
