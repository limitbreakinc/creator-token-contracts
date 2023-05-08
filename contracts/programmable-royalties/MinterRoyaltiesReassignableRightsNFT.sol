// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./helpers/ICloneableRoyaltyRightsERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract MinterRoyaltiesReassignableRightsNFT is IERC2981, ERC165 {

    error MinterRoyaltiesReassignableRightsNFT__MinterCannotBeZeroAddress();
    error MinterRoyaltiesReassignableRightsNFT__RoyaltyFeeWillExceedSalePrice();

    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public immutable royaltyFeeNumerator;
    ICloneableRoyaltyRightsERC721 public immutable royaltyRightsNFT;

    constructor(uint256 royaltyFeeNumerator_, address royaltyRightsNFTReference_) {
        if(royaltyFeeNumerator_ > FEE_DENOMINATOR) {
            revert MinterRoyaltiesReassignableRightsNFT__RoyaltyFeeWillExceedSalePrice();
        }

        royaltyFeeNumerator = royaltyFeeNumerator_;

        // Clone a reference implementation of the royalty rights NFT and bind it to this collection
        ICloneableRoyaltyRightsERC721 royaltyRightsNFT_ = 
            ICloneableRoyaltyRightsERC721(Clones.clone(royaltyRightsNFTReference_));
        royaltyRightsNFT_.initializeAndBindToCollection();

        royaltyRightsNFT = royaltyRightsNFT_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {

        address rightsHolder = address(0);

        try royaltyRightsNFT.ownerOf(tokenId) returns (address rightsTokenOwner) {
            rightsHolder = rightsTokenOwner;
        } catch {}

        return (rightsHolder, (salePrice * royaltyFeeNumerator) / FEE_DENOMINATOR);
    }

    function _onMinted(address minter, uint256 tokenId) internal {
        if (minter == address(0)) {
            revert MinterRoyaltiesReassignableRightsNFT__MinterCannotBeZeroAddress();
        }

        royaltyRightsNFT.mint(minter, tokenId);
    }

    function _onBurned(uint256 tokenId) internal {
        royaltyRightsNFT.burn(tokenId);
    }
}