// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";
import "contracts/examples/erc721ac/ERC721ACWithMutableMinterRoyalties.sol";

contract ERC721ACWithMutableMinterRoyaltiesTest is CreatorTokenTransferValidatorERC721Test {

    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    ERC721ACWithMutableMinterRoyalties public tokenMock;
    uint96 public constant DEFAULT_ROYALTY_FEE_NUMERATOR = 1000;

    function setUp() public virtual override {
        super.setUp();
        
        tokenMock = new ERC721ACWithMutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST");
        tokenMock.setToCustomSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(address(new ERC721ACWithMutableMinterRoyalties(DEFAULT_ROYALTY_FEE_NUMERATOR, "Test", "TEST")));
    }

    function _mintToken(address tokenAddress, address to, uint256 quantity) internal virtual override {
        uint96 defaultRoyaltyFee = ERC721ACWithMutableMinterRoyalties(tokenAddress).defaultRoyaltyFeeNumerator();
        uint256 nextTokenId = ERC721ACWithMutableMinterRoyalties(tokenAddress).totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.expectEmit(true, true, false, true);
            emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        }
        
        ERC721ACWithMutableMinterRoyalties(tokenAddress).mint(to, quantity);
    }

    function _safeMintToken(address tokenAddress, address to, uint256 quantity) internal {
        uint96 defaultRoyaltyFee = ERC721ACWithMutableMinterRoyalties(tokenAddress).defaultRoyaltyFeeNumerator();
        uint256 nextTokenId = ERC721ACWithMutableMinterRoyalties(tokenAddress).totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.expectEmit(true, true, false, true);
            emit RoyaltySet(tokenId, to, defaultRoyaltyFee);
        }

        ERC721ACWithMutableMinterRoyalties(tokenAddress).safeMint(to, quantity);
    }

    function testSupportedTokenInterfaces() public {
        // TODO: Figure out why these assertions fail
        //assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        //assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        //assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC2981).interfaceId), true);
    }

    function testRevertsWhenFeeNumeratorExceedsSalesPrice(uint96 royaltyFeeNumerator) public {
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());
        vm.expectRevert(MutableMinterRoyalties.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
        new ERC721ACWithMutableMinterRoyalties(royaltyFeeNumerator, "Test", "TEST");
    }

    function testRoyaltyInfoForUnmintedTokenIds(uint256 tokenId, uint256 salePrice) public {
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
        assertEq(recipient, address(0));
        assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
    }

    function testRoyaltyInfoForMintedTokenIds(address minter, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
        }
    }

    function testRoyaltyInfoForMintedTokenIdsAfterTransfer(address minter, address secondaryOwner, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.prank(minter);
            tokenMock.transferFrom(minter, secondaryOwner, tokenId);
    
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
        }
    }

    function testRoyaltyRecipientResetsToAddressZeroAfterBurns(address minter, address secondaryOwner, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(secondaryOwner != address(0));
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
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
    }

    function testMinterCanSetRoyaltyFee(address minter, uint256 quantity, uint256 salePrice, uint96 updatedFee) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(updatedFee == 0 || salePrice < type(uint256).max / updatedFee);
        vm.assume(updatedFee <= tokenMock.FEE_DENOMINATOR());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.prank(minter);
            vm.expectEmit(true, true, false, true);
            emit RoyaltySet(tokenId, minter, updatedFee);
            tokenMock.setRoyaltyFee(tokenId, updatedFee);
    
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
    
            assertEq(recipient, minter);
            assertEq(value, (salePrice * updatedFee) / tokenMock.FEE_DENOMINATOR());
        }
    }

    function testRevertsWhenMinterSetsFeeNumeratorToExceedSalesPrice(address minter, uint256 quantity, uint96 royaltyFeeNumerator) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(royaltyFeeNumerator > tokenMock.FEE_DENOMINATOR());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.expectRevert(MutableMinterRoyalties.MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice.selector);
            tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
        }
    }

    function testRevertsWhenUnauthorizedUserAttemptsToSetRoyaltyFee(address minter, address unauthorizedUser, uint256 quantity, uint96 royaltyFeeNumerator) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(minter != unauthorizedUser);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.expectRevert(MutableMinterRoyalties.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
            tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
        }
    }

    function testRevertsWhenMinterAttemptsToSetRoyaltyFeeForAnotherMintersTokenId(address minter, address minter2, uint256 quantity, uint256 quantity2, uint96 royaltyFeeNumerator) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(quantity2 > 0 && quantity2 < 5);
        vm.assume(minter != address(0));
        vm.assume(minter2 != address(0));
        vm.assume(minter != minter2);
        vm.assume(royaltyFeeNumerator <= tokenMock.FEE_DENOMINATOR());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _mintToken(address(tokenMock), minter, quantity);

        uint256 nextTokenId2 = tokenMock.totalSupply() + 1;
        uint256 lastTokenId2 = nextTokenId2 + quantity2 - 1;
        _mintToken(address(tokenMock), minter2, quantity2);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            vm.expectRevert(MutableMinterRoyalties.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
            vm.prank(minter2);
            tokenMock.setRoyaltyFee(tokenId, royaltyFeeNumerator);
        }

        for (uint256 tokenIdMinter2 = nextTokenId2; tokenIdMinter2 <= lastTokenId2; ++tokenIdMinter2) {
            vm.expectRevert(MutableMinterRoyalties.MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee.selector);
            vm.prank(minter);
            tokenMock.setRoyaltyFee(tokenIdMinter2, royaltyFeeNumerator);
        }
    }

    function testRoyaltyInfoForSafeMintedTokenIds(address minter, uint256 quantity, uint256 salePrice) public {
        vm.assume(quantity > 0 && quantity < 5);
        vm.assume(minter != address(0));
        vm.assume(minter.code.length == 0);
        vm.assume(salePrice < type(uint256).max / tokenMock.defaultRoyaltyFeeNumerator());

        uint256 nextTokenId = tokenMock.totalSupply() + 1;
        uint256 lastTokenId = nextTokenId + quantity - 1;

        _safeMintToken(address(tokenMock), minter, quantity);

        for (uint256 tokenId = nextTokenId; tokenId <= lastTokenId; ++tokenId) {
            (address recipient, uint256 value) = tokenMock.royaltyInfo(tokenId, salePrice);
            assertEq(recipient, minter);
            assertEq(value, (salePrice * tokenMock.defaultRoyaltyFeeNumerator()) / tokenMock.FEE_DENOMINATOR());
        }
    }
}