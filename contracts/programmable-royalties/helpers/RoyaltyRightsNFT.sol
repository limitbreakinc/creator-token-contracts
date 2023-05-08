// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ICloneableRoyaltyRightsERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract RoyaltyRightsNFT is ERC721, ICloneableRoyaltyRightsERC721 {

    error RoyaltyRightsNFT__CollectionAlreadyInitialized();
    error RoyaltyRightsNFT__OnlyBurnableFromCollection();
    error RoyaltyRightsNFT__OnlyMintableFromCollection();

    IERC721Metadata public collection;

    /// @dev Empty constructor so that it can be cloned and initialized by the real collection.
    constructor() ERC721("", "") {}

    function initializeAndBindToCollection() external override {
        if (address(collection) != address(0)) {
            revert RoyaltyRightsNFT__CollectionAlreadyInitialized();
        }

        collection = IERC721Metadata(_msgSender());
    }

    function mint(address to, uint256 tokenId) external override {
        if (_msgSender() != address(collection)) {
            revert RoyaltyRightsNFT__OnlyMintableFromCollection();
        }

        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external override {
        if (_msgSender() != address(collection)) {
            revert RoyaltyRightsNFT__OnlyBurnableFromCollection();
        }

        _burn(tokenId);
    }

    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked(collection.name(), " Royalty Rights"));
    }

    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked(collection.symbol(), "RR"));
    }

    /**
     * @notice Returns the token URI from the linked collection so that users can view 
     *         the image and details of the NFT associated with these royalty rights.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return collection.tokenURI(tokenId);
    }
}