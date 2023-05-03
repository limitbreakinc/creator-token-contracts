// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title ImmutableMinterRoyalties
 * @author Limit Break, Inc.
 * @dev An NFT mix-in contract implementing programmable royalties for minters
 */
abstract contract ImmutableMinterRoyalties is IERC2981, ERC165 {

    error ImmutableMinterRoyalties__MinterCannotBeZeroAddress();
    error ImmutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error ImmutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();

    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public immutable royaltyFeeNumerator;

    mapping (uint256 => address) private _minters;

    /**
     * @dev Constructor that sets the royalty fee numerator.
     * @param royaltyFeeNumerator_ The royalty fee numerator
     */
    constructor(uint256 royaltyFeeNumerator_) {
        if(royaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert ImmutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        royaltyFeeNumerator = royaltyFeeNumerator_;
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
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
        return (_minters[tokenId], (salePrice * royaltyFeeNumerator) / FEE_DENOMINATOR);
    }

    /**
     * @dev Internal function to be called when a new token is minted.
     *
     * @dev Throws when the minter is the zero address.
     * @dev Throws when a minter has already been assigned to the specified token ID.
     * @param minter The minter's address
     * @param tokenId The token ID
     */
    function _onMinted(address minter, uint256 tokenId) internal {
        if (minter == address(0)) {
            revert ImmutableMinterRoyalties__MinterCannotBeZeroAddress();
        }

        if (_minters[tokenId] != address(0)) {
            revert ImmutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
        }

        _minters[tokenId] = minter;
    }

    /**
     * @dev Internal function to be called when a token is burned.  Clears the minter's address.
     * @param tokenId The token ID
     */
    function _onBurned(uint256 tokenId) internal {
        delete _minters[tokenId];
    }
}