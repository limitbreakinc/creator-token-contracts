// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ImmutableMinterRoyalties is IERC2981, ERC165 {

    error MinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
    error MinterRoyalties__RoyaltyFeeWillExceedSalePrice();

    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public immutable royaltyFeeNumerator;

    mapping (uint256 => address) private _minters;

    constructor(uint256 royaltyFeeNumerator_) {
        if(royaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MinterRoyalties__RoyaltyFeeWillExceedSalePrice();
        }

        royaltyFeeNumerator = royaltyFeeNumerator_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        return (_minters[tokenId], (salePrice * royaltyFeeNumerator) / FEE_DENOMINATOR);
    }

    function _onMinted(address minter, uint256 tokenId) internal {
        if (_minters[tokenId] != address(0)) {
            revert MinterRoyalties__MinterHasAlreadyBeenAssignedToTokenId();
        }

        _minters[tokenId] = minter;
    }
}