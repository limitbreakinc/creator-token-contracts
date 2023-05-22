// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/OwnablePermissions.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title MutableMinterRoyaltiesBase
 * @author Limit Break, Inc.
 * @dev Base functionality of an NFT mix-in contract implementing programmable royalties for minters, allowing the minter of each token ID to 
 *      update the royalty fee percentage.
 */
abstract contract MutableMinterRoyaltiesBase is IERC2981, ERC165 {

    error MutableMinterRoyalties__MinterCannotBeZeroAddress();
    error MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee();
    error MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    uint96 public constant FEE_DENOMINATOR = 10_000;
    uint96 private _defaultRoyaltyFeeNumerator;

    mapping (uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /// @dev Emitted when royalty is set.
    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    /**
     * @notice Allows the minter to update the royalty fee percentage for a specific token ID.
     * @dev The caller must be the minter of the specified token ID.
     * @dev Throws when royaltyFeeNumerator is greater than FEE_DENOMINATOR
     * @dev Throws when the caller is not the minter of the specified token ID
     * @param tokenId The token ID
     * @param royaltyFeeNumerator The new royalty fee numerator
     
     */
    function setRoyaltyFee(uint256 tokenId, uint96 royaltyFeeNumerator) external {
        if (royaltyFeeNumerator > FEE_DENOMINATOR) {
            revert MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        RoyaltyInfo storage royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver != msg.sender) {
            revert MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee();
        }

        royalty.royaltyFraction = royaltyFeeNumerator;

        emit RoyaltySet(tokenId, msg.sender, royaltyFeeNumerator);
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function defaultRoyaltyFeeNumerator() public virtual view returns (uint96) {
        return _defaultRoyaltyFeeNumerator;
    }

    /**
     * @notice Returns the royalty info for a given token ID and sale price.
     * @dev Implements the IERC2981 interface.
     * @param tokenId The token ID
     * @param salePrice The sale price
     * @return receiver The minter's address
     * @return royaltyAmount The royalty amount
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty.royaltyFraction = defaultRoyaltyFeeNumerator();
        }

        return (royalty.receiver, (salePrice * royalty.royaltyFraction) / FEE_DENOMINATOR);
    }

    /**
     * @dev Sets the minter's address and royalty fraction for the specified token ID in the _tokenRoyaltyInfo mapping 
     *      when a new token is minted.
     * @dev Throws when minter is the zero address
     * @dev Throws when the minter has already been assigned to the specified token ID
     * @param minter The address of the minter
     * @param tokenId The token ID
     */
    function _onMinted(address minter, uint256 tokenId) internal {
        if (minter == address(0)) {
            revert MutableMinterRoyalties__MinterCannotBeZeroAddress();
        }
        
        if (_tokenRoyaltyInfo[tokenId].receiver != address(0)) {
            revert MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
        }

        uint96 defaultRoyaltyFeeNumerator_ = defaultRoyaltyFeeNumerator();

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo({
            receiver: minter,
            royaltyFraction: defaultRoyaltyFeeNumerator_
        });

        emit RoyaltySet(tokenId, minter, defaultRoyaltyFeeNumerator_);
    }

    /**
     * @dev Removes the royalty information from the _tokenRoyaltyInfo mapping for the specified token ID when a token 
     *      is burned.
     * @param tokenId The token ID
     */
    function _onBurned(uint256 tokenId) internal {
        delete _tokenRoyaltyInfo[tokenId];

        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFeeNumerator());
    }

    function _setDefaultRoyaltyFee(uint96 defaultRoyaltyFeeNumerator_) internal {
        if(defaultRoyaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        _defaultRoyaltyFeeNumerator = defaultRoyaltyFeeNumerator_;
    }
}

/**
 * @title MutableMinterRoyalties
 * @author Limit Break, Inc.
 * @notice Constructable MutableMinterRoyalties Contract implementation.
 */
abstract contract MutableMinterRoyalties is MutableMinterRoyaltiesBase {

    uint96 private immutable _defaultRoyaltyFeeNumeratorImmutable;

    constructor(uint96 defaultRoyaltyFeeNumerator_) {
        _setDefaultRoyaltyFee(defaultRoyaltyFeeNumerator_);
        _defaultRoyaltyFeeNumeratorImmutable = defaultRoyaltyFeeNumerator_;
    }

    function defaultRoyaltyFeeNumerator() public view override returns (uint96) {
        return _defaultRoyaltyFeeNumeratorImmutable;
    }
}

/**
 * @title MutableMinterRoyaltiesInitializable
 * @author Limit Break, Inc.
 * @notice Initializable MutableMinterRoyalties Contract implementation to allow for EIP-1167 clones. 
 */
abstract contract MutableMinterRoyaltiesInitializable is OwnablePermissions, MutableMinterRoyaltiesBase {

    error MutableMinterRoyaltiesInitializable__DefaultMinterRoyaltyFeeAlreadyInitialized();

    bool private _defaultMinterRoyaltyFeeInitialized;

    function initializeDefaultMinterRoyaltyFee(uint96 defaultRoyaltyFeeNumerator_) public {
        _requireCallerIsContractOwner();

        if(_defaultMinterRoyaltyFeeInitialized) {
            revert MutableMinterRoyaltiesInitializable__DefaultMinterRoyaltyFeeAlreadyInitialized();
        }

        _defaultMinterRoyaltyFeeInitialized = true;

        _setDefaultRoyaltyFee(defaultRoyaltyFeeNumerator_);
    }
}