// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "contracts/marketplaces/OrderFulfillmentOnchainRoyalties.sol";

contract ThirdPartyMarketplaceMock is OrderFulfillmentOnchainRoyalties {
    
    constructor() {}

    fallback() external payable {}
    receive() external payable {}

    function validateAndFulfillOrderERC721Native(
        address nftAddress,
        address payable seller,
        address payable buyer,
        uint256 tokenId,
        uint256 price,
        uint256 marketplaceFee,
        uint256 maxRoyaltyFeeNumerator,
        bytes memory signature
    ) external payable {
        // 1. Marketplaces Validate Order Details and Signatures
        // 2. Marketplaces Withdraw Platform Fees, If Applicable
        // 3. Marketplaces Translate Data To `OrderDetails` Struct And Call `fulfillSingleItemOrder`

        bool success;
        address to = address(this);

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(2300, to, marketplaceFee, 0, 0, 0, 0)
        }

        if (!success) {
            revert();
        }

        fulfillSingleItemOrder(OrderDetails({
            protocol: CollectionProtocols.ERC721,
            seller: seller,
            buyer: buyer,
            paymentMethod: address(0),
            tokenAddress: nftAddress,
            tokenId: tokenId,
            amount: 1,
            priceBeforePlatformFees: price,
            platformFeesDeducted: marketplaceFee,
            maxRoyaltyFeeNumerator: maxRoyaltyFeeNumerator
        }), 2300);
    }

    function validateAndFulfillOrderERC1155Native(
        address nftAddress,
        address payable seller,
        address payable buyer,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 marketplaceFee,
        uint256 maxRoyaltyFeeNumerator,
        bytes memory signature
    ) external payable {
        // 1. Marketplaces Validate Order Details and Signatures
        // 2. Marketplaces Withdraw Platform Fees, If Applicable
        // 3. Marketplaces Translate Data To `OrderDetails` Struct And Call `fulfillSingleItemOrder`

        bool success;
        address to = address(this);

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(2300, to, marketplaceFee, 0, 0, 0, 0)
        }

        if (!success) {
            revert();
        }

        fulfillSingleItemOrder(OrderDetails({
            protocol: CollectionProtocols.ERC1155,
            seller: seller,
            buyer: buyer,
            paymentMethod: address(0),
            tokenAddress: nftAddress,
            tokenId: tokenId,
            amount: amount,
            priceBeforePlatformFees: price,
            platformFeesDeducted: marketplaceFee,
            maxRoyaltyFeeNumerator: maxRoyaltyFeeNumerator
        }), 2300);
    }
}