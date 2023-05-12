// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "contracts/examples/erc721c/ERC721CWithImmutableMinterRoyalties.sol";

contract ERC721CWithImmutableMinterRoyaltiesTest is CreatorTokenTransferValidatorERC721Test {

    ERC721CWithImmutableMinterRoyalties public tokenMock;
    uint256 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    function setUp() public virtual override {
        super.setUp();
        
        tokenMock = new ERC721CWithImmutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST");
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(address(new ERC721CWithImmutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST")));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        ERC721CWithImmutableMinterRoyalties(tokenAddress).mint(to, tokenId);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 tokenId) internal {
        ERC721CWithImmutableMinterRoyalties(tokenAddress).safeMint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(uint256 royaltyFeeNumerator) public {
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(ImmutableMinterRoyaltiesBase.ImmutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        new ERC721CWithImmutableMinterRoyalties(royaltyFeeNumerator, "Test", "TEST");
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(address minter, address secondaryOwner, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(address minter, address secondaryOwner, uint256 tokenId, uint256 salePrice) public {
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
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.expectRevert(ImmutableMinterRoyaltiesBase.ImmutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId.selector);
        _mintToken(address(tokenMock), minter, tokenId);
    }

    function testBurnedTokenIdsCanBeReminted(address minter, address secondaryOwner, address reminter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(reminter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _mintToken(address(tokenMock), minter, tokenId);

        vm.prank(minter);
        tokenMock.transferFrom(minter, secondaryOwner, tokenId);

        vm.prank(secondaryOwner);
        tokenMock.burn(tokenId);

        _mintToken(address(tokenMock), reminter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, reminter);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 tokenId, uint256 salePrice) public {
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(salePrice < type(uint256).max / tokenMock.royaltyFeeNumerator());

        _safeMintToken(address(tokenMock), minter, tokenId);

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, minter);
        assertEq(value, (salePrice * tokenMock.royaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }
}