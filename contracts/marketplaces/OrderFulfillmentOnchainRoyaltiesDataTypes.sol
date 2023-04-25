// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum CollectionProtocols { ERC721, ERC1155 }

struct OrderDetails {
    CollectionProtocols protocol;
    address seller;
    address buyer;
    address paymentMethod;
    address tokenAddress;
    uint256 tokenId;
    uint256 amount;
    uint256 priceBeforePlatformFees;
    uint256 platformFeesDeducted;
    uint256 maxRoyaltyFeeNumerator;
}

struct SellerAndRoyaltySplitProceeds {
    address royaltyRecipient;
    uint256 royaltyProceeds;
    uint256 sellerProceeds;
}