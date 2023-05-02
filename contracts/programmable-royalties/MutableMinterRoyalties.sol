// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract MutableMinterRoyalties is IERC2981, ERC165 {

    error MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MutableMinterRoyalties__OnlyMinterCanChangeRoyaltyFee();
    error MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    uint96 public constant FEE_DENOMINATOR = 10_000;
    uint96 public immutable defaultRoyaltyFeeNumerator;

    mapping (uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /// @dev Emitted when royalty is set.
    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    constructor(uint96 defaultRoyaltyFeeNumerator_) {
        if(defaultRoyaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MutableMinterRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        defaultRoyaltyFeeNumerator = defaultRoyaltyFeeNumerator_;
    }

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

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty.royaltyFraction = defaultRoyaltyFeeNumerator;
        }

        return (royalty.receiver, (salePrice * royalty.royaltyFraction) / FEE_DENOMINATOR);
    }

    function _onMinted(address minter, uint256 tokenId) internal {
        if (_tokenRoyaltyInfo[tokenId].receiver != address(0)) {
            revert MutableMinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
        }

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo({
            receiver: minter,
            royaltyFraction: defaultRoyaltyFeeNumerator
        });

        emit RoyaltySet(tokenId, minter, defaultRoyaltyFeeNumerator);
    }

    function _onBurned(uint256 tokenId) internal {
        delete _tokenRoyaltyInfo[tokenId];

        emit RoyaltySet(tokenId, address(0), defaultRoyaltyFeeNumerator);
    }
}