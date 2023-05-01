// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ThirdPartyMarketplaceMock.sol";
import "./mocks/ERC721CMock.sol";
import "./mocks/ERC1155CMock.sol";
import "./interfaces/ITestCreatorToken.sol";
import "contracts/utils/TransferPolicy.sol";
import "contracts/utils/CreatorTokenTransferValidator.sol";
import "contracts/examples/erc721c/ERC721CWithMutableMinterRoyalties.sol";

contract OrderFulfillmentOnchainRoyaltiesTest is Test {
    
    ThirdPartyMarketplaceMock public marketplace;

    function setUp() public virtual {
        marketplace = new ThirdPartyMarketplaceMock();
    }

    function testValidateAndFulfillOrderERC721Native(
        address creator,
        address minter,
        address payable seller,
        address payable buyer,
        uint256 tokenId,
        uint256 price,
        uint256 marketplaceFee,
        uint256 maxRoyaltyFeeNumerator,
        uint96 actualRoyaltyFeeNumerator
    ) public {
        vm.assume(price < type(uint128).max);
        vm.assume(marketplaceFee < price);
        _sanitizeAddress(creator);
        _sanitizeAddress(minter);
        _sanitizeAddress(seller);
        _sanitizeAddress(buyer);
        vm.assume(address(marketplace) != creator);
        vm.assume(address(marketplace) != minter);
        vm.assume(address(marketplace) != seller);
        vm.assume(address(marketplace) != buyer);
        vm.assume(seller != buyer);
        vm.assume(minter != seller);
        vm.assume(minter != buyer);
        vm.assume(maxRoyaltyFeeNumerator < 10000);
        vm.assume(actualRoyaltyFeeNumerator < 10000);
        vm.assume(actualRoyaltyFeeNumerator <= maxRoyaltyFeeNumerator);
        uint256 maxRoyaltyFee = (price * maxRoyaltyFeeNumerator) / 10000;
        vm.assume(marketplaceFee + maxRoyaltyFee <= price);
        uint256 expectedRoyaltyFee = (price * actualRoyaltyFeeNumerator) / 10000;

        vm.prank(creator);
        ERC721CWithMutableMinterRoyalties token = new ERC721CWithMutableMinterRoyalties(actualRoyaltyFeeNumerator, "Test", "TEST");

        vm.assume(creator != address(token));
        vm.assume(minter != address(token));
        vm.assume(seller != address(token));
        vm.assume(buyer != address(token));
        vm.assume(creator.code.length == 0);
        vm.assume(minter.code.length == 0);
        vm.assume(seller.code.length == 0);
        vm.assume(buyer.code.length == 0);

        vm.startPrank(minter);
        token.mint(minter, tokenId);
        token.transferFrom(minter, seller, tokenId);
        vm.stopPrank();

        vm.prank(seller);
        token.setApprovalForAll(address(marketplace), true);

        vm.deal(buyer, price);

        vm.prank(buyer);
        marketplace.validateAndFulfillOrderERC721Native{value: price}(
            address(token), 
            seller, 
            buyer, 
            tokenId, 
            price, 
            marketplaceFee, 
            maxRoyaltyFeeNumerator, 
            "");

        assertEq(buyer.balance, 0);
        assertEq(address(marketplace).balance, marketplaceFee);
        assertEq(minter.balance, expectedRoyaltyFee);
        assertEq(seller.balance, price - marketplaceFee - expectedRoyaltyFee);
        assertEq(token.ownerOf(tokenId), buyer);
    }

    function testValidateAndFulfillOrderERC1155Native(
        address creator,
        address minter,
        address payable seller,
        address payable buyer,
        uint256 tokenId,
        uint256 price,
        uint256 marketplaceFee,
        uint256 amount
    ) public {
        vm.assume(price < type(uint128).max);
        vm.assume(marketplaceFee < price);
        _sanitizeAddress(creator);
        _sanitizeAddress(minter);
        _sanitizeAddress(seller);
        _sanitizeAddress(buyer);
        vm.assume(address(marketplace) != creator);
        vm.assume(address(marketplace) != minter);
        vm.assume(address(marketplace) != seller);
        vm.assume(address(marketplace) != buyer);
        vm.assume(seller != buyer);
        vm.assume(minter != seller);
        vm.assume(minter != buyer);
        vm.assume(marketplaceFee <= price);
        vm.assume(amount > 0);

        vm.prank(creator);
        ERC1155CMock token = new ERC1155CMock();

        vm.assume(creator != address(token));
        vm.assume(minter != address(token));
        vm.assume(seller != address(token));
        vm.assume(buyer != address(token));
        vm.assume(creator.code.length == 0);
        vm.assume(minter.code.length == 0);
        vm.assume(seller.code.length == 0);
        vm.assume(buyer.code.length == 0);

        vm.startPrank(minter);
        token.mint(minter, tokenId, amount);
        token.safeTransferFrom(minter, seller, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(seller);
        token.setApprovalForAll(address(marketplace), true);

        vm.assume(seller.balance == 0);
        vm.assume(buyer.balance == 0);
        vm.assume(minter.balance == 0);

        vm.deal(buyer, price);

        vm.prank(buyer);
        marketplace.validateAndFulfillOrderERC1155Native{value: price}(
            address(token), 
            seller, 
            buyer, 
            tokenId, 
            amount,
            price, 
            marketplaceFee, 
            0, 
            "");

        assertEq(buyer.balance, 0);
        assertEq(address(marketplace).balance, marketplaceFee);
        assertEq(minter.balance, 0);
        assertEq(seller.balance, price - marketplaceFee);
        assertEq(token.balanceOf(buyer, tokenId), amount);
    }

    function _sanitizeAddress(address addr) private {
        vm.assume(uint160(addr) > 0xA);
        vm.assume(addr != address(0x000000000000000000636F6e736F6c652e6c6f67));
    }
}