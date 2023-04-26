// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

abstract contract MinterCreatorSharedRoyalties is IERC2981, ERC165 {
    error MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice();
    error MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();

    enum ReleaseTo {
        Minter,
        Creator
    }

    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public immutable royaltyFeeNumerator;
    uint256 public immutable minterShares;
    uint256 public immutable creatorShares;
    address public immutable creator;

    mapping (uint256 => address) private _minters;
    mapping (uint256 => address) private _paymentSplitters;
    mapping (address => address[]) private _minterPaymentSplitters;

    constructor(uint256 royaltyFeeNumerator_, uint256 minterShares_, uint256 creatorShares_, address creator_) {
        if(royaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        royaltyFeeNumerator = royaltyFeeNumerator_;
        minterShares = minterShares_;
        creatorShares = creatorShares_;
        creator = creator_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the royalty fee and recipient for a given token.
     * @param  tokenId   The id of the token whose royalty info is being queried.
     * @param  salePrice The sale price of the token.
     * @return           The royalty fee and recipient for a given token.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {
        return (_paymentSplitters[tokenId], (salePrice * royaltyFeeNumerator) / FEE_DENOMINATOR);
    }

    /**
     * @notice Returns the minter of the token with id `tokenId`.
     * @param  tokenId  The id of the token whose minter is being queried.
     * @return         The minter of the token with id `tokenId`.
     */
    function minterOf(uint256 tokenId) external view returns (address) {
        return _minters[tokenId];
    }

    /**
     * @notice Returns the payment splitter of the token with id `tokenId`.
     * @param  tokenId  The id of the token whose payment splitter is being queried.
     * @return         The payment splitter of the token with id `tokenId`.
     */
    function paymentSplitterOf(uint256 tokenId) external view returns (address) {
        return _paymentSplitters[tokenId];
    }

    /**
     * @notice Returns the payment splitters of the minter `minter`.
     * @param  minter  The minter whose payment splitters are being queried.
     * @return         The payment splitters of the minter `minter`.
     */
    function paymentSplittersOfMinter(address minter) external view returns (address[] memory) {
        return _minterPaymentSplitters[minter];
    }

    /**
     * @notice Returns the amount of native funds that can be released to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose releasable funds are being queried.
     * @param  releaseTo Specifies whether the minter or creator should be queried.
     * @return           The amount of native funds that can be released to the minter or creator of the token with id `tokenId`.
     */
    function releasableNativeFunds(uint256 tokenId, ReleaseTo releaseTo) external view returns (uint256) {
        PaymentSplitter paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            return paymentSplitter.releasable(payable(_minters[tokenId]));
        } else {
            return paymentSplitter.releasable(payable(creator));
        }
    }

    /**
     * @notice Returns the amount of ERC20 funds that can be released to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose releasable funds are being queried.
     * @param  coin      The address of the ERC20 token whose releasable funds are being queried.
     * @param  releaseTo Specifies whether the minter or creator should be queried.
     * @return           The amount of ERC20 funds that can be released to the minter or creator of the token with id `tokenId`.
     */
    function releasableERC20Funds(uint256 tokenId, address coin, ReleaseTo releaseTo) external view returns (uint256) {
        PaymentSplitter paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            return paymentSplitter.releasable(IERC20(coin), _minters[tokenId]);
        } else {
            return paymentSplitter.releasable(IERC20(coin), creator);
        }
    }

    /**
     * @notice Releases all available native funds to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose funds are being released.
     * @param  releaseTo Specifies whether the minter or creator should be released to.
     */
    function releaseNativeFunds(uint256 tokenId, ReleaseTo releaseTo) external {
        PaymentSplitter paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            paymentSplitter.release(payable(_minters[tokenId]));
        } else {
            paymentSplitter.release(payable(creator));
        }
    }

    /**
     * @notice Releases all available ERC20 funds to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose funds are being released.
     * @param  coin      The address of the ERC20 token whose funds are being released.
     * @param  releaseTo Specifies whether the minter or creator should be released to.
     */
    function releaseERC20Funds(uint256 tokenId, address coin, ReleaseTo releaseTo) external {
        PaymentSplitter paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if(releaseTo == ReleaseTo.Minter) {
            paymentSplitter.release(IERC20(coin), _minters[tokenId]);
        } else {
            paymentSplitter.release(IERC20(coin), creator);
        }
    }

    /**
     * @dev   Internal function that must be called when a token is minted.
     *        Creates a payment splitter for the minter and creator of the token to share royalties.
     * @param minter  The minter of the token.
     * @param tokenId The id of the token that was minted.
     */
    function _onMinted(address minter, uint256 tokenId) internal {
        if (_minters[tokenId] != address(0)) {
            revert MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
        }

        address paymentSplitter = _createPaymentSplitter(minter);
        _paymentSplitters[tokenId] = paymentSplitter;
        _minterPaymentSplitters[minter].push(paymentSplitter);
        _minters[tokenId] = minter;
    }

    /**
     * @dev  Internal function that must be called when a token is burned.
     *       Deletes the payment splitter mapping and minter mapping for the token in case it is ever re-minted.
     * @param tokenId The id of the token that was burned.
     */
    function _onBurned(uint256 tokenId) internal {
        delete _paymentSplitters[tokenId];
        delete _minters[tokenId];
    }

    /**
     * @dev   Internal function that creates a payment splitter for the minter and creator of the token to share royalties.
     * @param minter The minter of the token.
     * @return       The address of the payment splitter.
     */
    function _createPaymentSplitter(address minter) private returns (address) {
        address[] memory payees = new address[](2);
        payees[0] = minter;
        payees[1] = creator;

        uint256[] memory shares = new uint256[](2);
        shares[0] = minterShares;
        shares[1] = creatorShares;

        return address(new PaymentSplitter(payees, shares));
    }

    function _getPaymentSplitterForTokenOrRevert(uint256 tokenId) private view returns (PaymentSplitter) {
        address paymentSplitterForToken = _paymentSplitters[tokenId];
        if(paymentSplitterForToken == address(0)) {
            revert MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();
        }

        return PaymentSplitter(payable(paymentSplitterForToken));
    }
}