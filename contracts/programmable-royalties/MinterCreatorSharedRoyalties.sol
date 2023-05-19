// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./helpers/IPaymentSplitterInitializable.sol";
import "../access/OwnablePermissions.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title MinterCreatorSharedRoyaltiesBase
 * @author Limit Break, Inc.
 * @dev Base functionality of an NFT mix-in contract implementing programmable royalties.  Royalties are shared between creators and minters.
 */
abstract contract MinterCreatorSharedRoyaltiesBase is IERC2981, ERC165 {

    error MinterCreatorSharedRoyalties__CreatorCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__CreatorSharesCannotBeZero();
    error MinterCreatorSharedRoyalties__MinterCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MinterCreatorSharedRoyalties__MinterSharesCannotBeZero();
    error MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();
    error MinterCreatorSharedRoyalties__PaymentSplitterReferenceCannotBeZeroAddress();
    error MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice();

    enum ReleaseTo {
        Minter,
        Creator
    }

    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 private _royaltyFeeNumerator;
    uint256 private _minterShares;
    uint256 private _creatorShares;
    address private _creator;
    address private _paymentSplitterReference;

    mapping (uint256 => address) private _minters;
    mapping (uint256 => address) private _paymentSplitters;
    mapping (address => address[]) private _minterPaymentSplitters;

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyFeeNumerator() public virtual view returns (uint256) {
        return _royaltyFeeNumerator;
    }

    function minterShares() public virtual view returns (uint256) {
        return _minterShares;
    }

    function creatorShares() public virtual view returns (uint256) {
        return _creatorShares;
    }

    function creator() public virtual view returns (address) {
        return _creator;
    }

    function paymentSplitterReference() public virtual view returns (address) {
        return _paymentSplitterReference;
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
        return (_paymentSplitters[tokenId], (salePrice * royaltyFeeNumerator()) / FEE_DENOMINATOR);
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
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            return paymentSplitter.releasable(payable(_minters[tokenId]));
        } else {
            return paymentSplitter.releasable(payable(creator()));
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
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            return paymentSplitter.releasable(IERC20(coin), _minters[tokenId]);
        } else {
            return paymentSplitter.releasable(IERC20(coin), creator());
        }
    }

    /**
     * @notice Releases all available native funds to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose funds are being released.
     * @param  releaseTo Specifies whether the minter or creator should be released to.
     */
    function releaseNativeFunds(uint256 tokenId, ReleaseTo releaseTo) external {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if (releaseTo == ReleaseTo.Minter) {
            paymentSplitter.release(payable(_minters[tokenId]));
        } else {
            paymentSplitter.release(payable(creator()));
        }
    }

    /**
     * @notice Releases all available ERC20 funds to the minter or creator of the token with id `tokenId`.
     * @param  tokenId   The id of the token whose funds are being released.
     * @param  coin      The address of the ERC20 token whose funds are being released.
     * @param  releaseTo Specifies whether the minter or creator should be released to.
     */
    function releaseERC20Funds(uint256 tokenId, address coin, ReleaseTo releaseTo) external {
        IPaymentSplitterInitializable paymentSplitter = _getPaymentSplitterForTokenOrRevert(tokenId);

        if(releaseTo == ReleaseTo.Minter) {
            paymentSplitter.release(IERC20(coin), _minters[tokenId]);
        } else {
            paymentSplitter.release(IERC20(coin), creator());
        }
    }

    /**
     * @dev   Internal function that must be called when a token is minted.
     *        Creates a payment splitter for the minter and creator of the token to share royalties.
     * @param minter  The minter of the token.
     * @param tokenId The id of the token that was minted.
     */
    function _onMinted(address minter, uint256 tokenId) internal {
        if (minter == address(0)) {
            revert MinterCreatorSharedRoyalties__MinterCannotBeZeroAddress();
        }

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
        address creator_ = creator();
        address paymentSplitterReference_ = paymentSplitterReference();

        IPaymentSplitterInitializable paymentSplitter = 
            IPaymentSplitterInitializable(Clones.clone(paymentSplitterReference_));

        if (minter == creator_) {
            address[] memory payees = new address[](1);
            payees[0] = creator_;

            uint256[] memory shares = new uint256[](1);
            shares[0] = minterShares() + creatorShares();

            paymentSplitter.initializePaymentSplitter(payees, shares);
        } else {
            address[] memory payees = new address[](2);
            payees[0] = minter;
            payees[1] = creator_;

            uint256[] memory shares = new uint256[](2);
            shares[0] = minterShares();
            shares[1] = creatorShares();

            paymentSplitter.initializePaymentSplitter(payees, shares);
        }

        return address(paymentSplitter);
    }

    /**
     * @dev Gets the payment splitter for the specified token id or reverts if it does not exist.
     */
    function _getPaymentSplitterForTokenOrRevert(uint256 tokenId) private view returns (IPaymentSplitterInitializable) {
        address paymentSplitterForToken = _paymentSplitters[tokenId];
        if(paymentSplitterForToken == address(0)) {
            revert MinterCreatorSharedRoyalties__PaymentSplitterDoesNotExistForSpecifiedTokenId();
        }

        return IPaymentSplitterInitializable(payable(paymentSplitterForToken));
    }

    function _setRoyaltyFeeNumeratorAndShares(
        uint256 royaltyFeeNumerator_, 
        uint256 minterShares_, 
        uint256 creatorShares_, 
        address creator_,
        address paymentSplitterReference_) internal {
        if(royaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MinterCreatorSharedRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        if (minterShares_ == 0) {
            revert MinterCreatorSharedRoyalties__MinterSharesCannotBeZero();
        }

        if (creatorShares_ == 0) {
            revert MinterCreatorSharedRoyalties__CreatorSharesCannotBeZero();
        }

        if (creator_ == address(0)) {
            revert MinterCreatorSharedRoyalties__CreatorCannotBeZeroAddress();
        }

        if (paymentSplitterReference_ == address(0)) {
            revert MinterCreatorSharedRoyalties__PaymentSplitterReferenceCannotBeZeroAddress();
        }

        _royaltyFeeNumerator = royaltyFeeNumerator_;
        _minterShares = minterShares_;
        _creatorShares = creatorShares_;
        _creator = creator_;
        _paymentSplitterReference = paymentSplitterReference_;
    }
}

/**
 * @title MinterCreatorSharedRoyalties
 * @author Limit Break, Inc.
 * @notice Constructable MinterCreatorSharedRoyalties Contract implementation.
 */
abstract contract MinterCreatorSharedRoyalties is MinterCreatorSharedRoyaltiesBase {

    uint256 private immutable _royaltyFeeNumeratorImmutable;
    uint256 private immutable _minterSharesImmutable;
    uint256 private immutable _creatorSharesImmutable;
    address private immutable _creatorImmutable;
    address private immutable _paymentSplitterReferenceImmutable;

    /**
     * @dev Constructor that sets the royalty fee numerator, creator, and minter/creator shares.
     * @dev Throws when defaultRoyaltyFeeNumerator_ is greater than FEE_DENOMINATOR
     * @param royaltyFeeNumerator_ The royalty fee numerator
     * @param minterShares_  The number of shares minters get allocated in payment processors
     * @param creatorShares_ The number of shares creators get allocated in payment processors
     * @param creator_       The NFT creator's royalty wallet
     */
    constructor(
        uint256 royaltyFeeNumerator_, 
        uint256 minterShares_, 
        uint256 creatorShares_, 
        address creator_,
        address paymentSplitterReference_) {
        _setRoyaltyFeeNumeratorAndShares(
            royaltyFeeNumerator_, 
            minterShares_, 
            creatorShares_, 
            creator_, 
            paymentSplitterReference_);

        _royaltyFeeNumeratorImmutable = royaltyFeeNumerator_;
        _minterSharesImmutable = minterShares_;
        _creatorSharesImmutable = creatorShares_;
        _creatorImmutable = creator_;
        _paymentSplitterReferenceImmutable = paymentSplitterReference_;
    }

    function royaltyFeeNumerator() public view override returns (uint256) {
        return _royaltyFeeNumeratorImmutable;
    }

    function minterShares() public view override returns (uint256) {
        return _minterSharesImmutable;
    }

    function creatorShares() public view override returns (uint256) {
        return _creatorSharesImmutable;
    }

    function creator() public view override returns (address) {
        return _creatorImmutable;
    }

    function paymentSplitterReference() public view override returns (address) {
        return _paymentSplitterReferenceImmutable;
    }
}

/**
 * @title MinterCreatorSharedRoyaltiesInitializable
 * @author Limit Break, Inc.
 * @notice Initializable MinterCreatorSharedRoyalties Contract implementation to allow for EIP-1167 clones. 
 */
abstract contract MinterCreatorSharedRoyaltiesInitializable is OwnablePermissions, MinterCreatorSharedRoyaltiesBase {

    error MinterCreatorSharedRoyaltiesInitializable__RoyaltyFeeAndSharesAlreadyInitialized();

    bool private _royaltyFeeAndSharesInitialized;

    function initializeMinterRoyaltyFee(
        uint256 royaltyFeeNumerator_, 
        uint256 minterShares_, 
        uint256 creatorShares_, 
        address creator_,
        address paymentSplitterReference_) public {
        _requireCallerIsContractOwner();

        if(_royaltyFeeAndSharesInitialized) {
            revert MinterCreatorSharedRoyaltiesInitializable__RoyaltyFeeAndSharesAlreadyInitialized();
        }

        _royaltyFeeAndSharesInitialized = true;

        _setRoyaltyFeeNumeratorAndShares(
            royaltyFeeNumerator_, 
            minterShares_, 
            creatorShares_, 
            creator_, 
            paymentSplitterReference_);
    }
}