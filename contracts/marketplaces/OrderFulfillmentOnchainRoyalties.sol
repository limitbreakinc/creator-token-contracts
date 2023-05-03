// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OrderFulfillmentOnchainRoyaltiesDataTypes.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title OrderFulfillmentOnchainRoyalties
 * @author Limit Break, Inc.
 * @dev This mix-in contract allows for on-chain royalties management during NFT sales.
 *      It can be used as-is or as an example for third-party marketplace contracts to read
 *      on-chain royalties and payout proceeds from NFT sales to the royalty recipient, seller,
 *      and dispense the NFTs to the buyer.
 */
abstract contract OrderFulfillmentOnchainRoyalties {

    error OrderFulfillmentOnchainRoyalties__FailedToTransferProceeds();
    error OrderFulfillmentOnchainRoyalties__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
    error OrderFulfillmentOnchainRoyalties__PlatformAndRoyaltyFeesWillExceedSalePrice();
    error OrderFulfillmentOnchainRoyalties__PlatformFeesExceededOriginalSalePrice();

    uint256 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @notice Fulfill a single item order. Issues payments to seller and applicable royalty recipient.
     *         Transfers the purchased token to the buyer.
     * @dev    The implementing marketplace contract is responsible for collecting platform fees and
     *         passing along the original sale price and the amount of platform fees withheld to this function.
     * @param orderDetails Struct containing the order details.
     * @param pushPaymentGasLimit Gas limit for pushing native payments.
     */
    function fulfillSingleItemOrder(
        OrderDetails memory orderDetails,
        uint256 pushPaymentGasLimit) internal {

        _fullfillOrderForSingleItem(
            orderDetails,
            pushPaymentGasLimit,
            IERC20(orderDetails.paymentMethod), 
            orderDetails.paymentMethod == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
            orderDetails.protocol == CollectionProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token);
    }

    function _fullfillOrderForSingleItem(
        OrderDetails memory orderDetails,
        uint256 pushPaymentGasLimit,
        IERC20 paymentMethod,
        function(address,address,IERC20,uint256,uint256) internal funcPayout,
        function(address,address,address,uint256,uint256) internal funcDispenseToken) private {
        
        SellerAndRoyaltySplitProceeds memory proceeds =
            _computePaymentSplits(
                orderDetails.priceBeforePlatformFees,
                orderDetails.platformFeesDeducted,
                orderDetails.tokenAddress,
                orderDetails.tokenId,
                orderDetails.maxRoyaltyFeeNumerator
            );

        if (proceeds.royaltyProceeds > 0) {
            funcPayout(
                proceeds.royaltyRecipient, 
                orderDetails.buyer, 
                paymentMethod, 
                proceeds.royaltyProceeds, 
                pushPaymentGasLimit
            );
        }

        if (proceeds.sellerProceeds > 0) {
            funcPayout(
                orderDetails.seller, 
                orderDetails.buyer, 
                paymentMethod, 
                proceeds.sellerProceeds, 
                pushPaymentGasLimit);
        }

        funcDispenseToken(
            orderDetails.seller, 
            orderDetails.buyer, 
            orderDetails.tokenAddress, 
            orderDetails.tokenId, 
            orderDetails.amount);
    }

    function _computePaymentSplits(
        uint256 priceBeforePlatformFees,
        uint256 platformFeesDeducted,
        address tokenAddress,
        uint256 tokenId,
        uint256 maxRoyaltyFeeNumerator) private view returns (SellerAndRoyaltySplitProceeds memory proceeds) {

        if (platformFeesDeducted > priceBeforePlatformFees) {
            revert OrderFulfillmentOnchainRoyalties__PlatformFeesExceededOriginalSalePrice();
        }

        uint256 maxRoyaltyAmount = (priceBeforePlatformFees * maxRoyaltyFeeNumerator) / FEE_DENOMINATOR;

        if (platformFeesDeducted + maxRoyaltyAmount > priceBeforePlatformFees) {
            revert OrderFulfillmentOnchainRoyalties__PlatformAndRoyaltyFeesWillExceedSalePrice();
        }
        
        proceeds = SellerAndRoyaltySplitProceeds({
            royaltyRecipient: address(0),
            royaltyProceeds: 0,
            sellerProceeds: 0
        });

        proceeds.sellerProceeds = priceBeforePlatformFees - platformFeesDeducted;

        (bool success, bytes memory result) = 
            tokenAddress.staticcall(
                abi.encodeWithSelector(IERC2981.royaltyInfo.selector, tokenId, priceBeforePlatformFees)
            );

        if (success && result.length == 64) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(result, (address, uint256));

            if (royaltyReceiver == address(0)) {
                royaltyAmount = 0;
            }

            if (royaltyAmount > 0) {
                if (royaltyAmount > maxRoyaltyAmount) {
                    revert OrderFulfillmentOnchainRoyalties__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
                }

                proceeds.royaltyRecipient = royaltyReceiver;
                proceeds.royaltyProceeds = royaltyAmount;

                unchecked {
                    proceeds.sellerProceeds -= royaltyAmount;
                }
            }
        }

        return proceeds;
    }

    function _pushProceeds(address to, uint256 proceeds, uint256 pushPaymentGasLimit) private {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(pushPaymentGasLimit, to, proceeds, 0, 0, 0, 0)
        }

        if (!success) {
            revert OrderFulfillmentOnchainRoyalties__FailedToTransferProceeds();
        }
    }

    function _payoutNativeCurrency(
        address payee, 
        address /*payer*/, 
        IERC20 /*paymentMethod*/, 
        uint256 proceeds, 
        uint256 gasLimit_) internal {
        _pushProceeds(payee, proceeds, gasLimit_);
    }

    function _payoutCoinCurrency(
        address payee, 
        address payer, 
        IERC20 paymentMethod, 
        uint256 proceeds, 
        uint256 /*gasLimit_*/) internal {
        SafeERC20.safeTransferFrom(paymentMethod, payer, payee, proceeds);
    }

    function _dispenseERC721Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 /*amount*/) internal {
        IERC721(tokenAddress).transferFrom(from, to, tokenId);
    }

    function _dispenseERC1155Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount) internal {
        IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "");
    }
}
