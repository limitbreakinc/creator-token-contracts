// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../AdventureERC721C.sol";
import "./ERC721CW.sol";

/**
 * @title AdventureERC721CW
 * @author Limit Break, Inc.
 * @notice Extends AdventureERC721-C contracts and adds a staking feature used to wrap another ERC721 contract.
 * The wrapper token gives the developer access to the same set of controls present in the ERC721-C standard.
 * in addition to Limit Break's AdventureERC721 staking features.  
 * Holders opt-in to this contract by staking, and it is possible for holders to unstake at the developers' discretion. 
 * The intent of this contract is to allow developers to upgrade existing NFT collections and provide enhanced features.
 *
 * @notice Creators also have discretion to set optional staker constraints should they wish to restrict staking to 
 *         EOA accounts only.
 */
abstract contract AdventureERC721CW is ERC721WrapperBase, AdventureERC721C {
    
    /// @dev Points to an external ERC721 contract that will be wrapped via staking.
    IERC721 private immutable wrappedCollectionImmutable;

    constructor(address wrappedCollectionAddress_) {
        _setWrappedCollectionAddress(wrappedCollectionAddress_);
        wrappedCollectionImmutable = IERC721(wrappedCollectionAddress_);
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorTokenWrapperERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function getWrappedCollectionAddress() public virtual view override returns (address) {
        return address(wrappedCollectionImmutable);
    }

    function _requireCallerIsVerifiedEOA() internal view virtual override {
        ICreatorTokenTransferValidator transferValidator_ = getTransferValidator();
        if (address(transferValidator_) != address(0)) {
            if (!transferValidator_.isVerifiedEOA(_msgSender())) {
                revert ERC721WrapperBase__CallerSignatureNotVerifiedInEOARegistry();
            }
        }
    }

    function _doTokenMint(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }

    function _doTokenBurn(uint256 tokenId) internal virtual override {
        _burn(tokenId);
    }

    function _getOwnerOfToken(uint256 tokenId) internal view virtual override returns (address) {
        return ownerOf(tokenId);
    }

    function _tokenExists(uint256 tokenId) internal view virtual override returns (bool) {
        return _exists(tokenId);
    }
}

/**
 * @title AdventureERC721CWInitializable
 * @author Limit Break, Inc.
 * @notice Initializable implementation of the AdventureERC721CW contract to allow for EIP-1167 clones.
 */
abstract contract AdventureERC721CWInitializable is ERC721WrapperBase, AdventureERC721CInitializable {

    error AdventureERC721CWInitializable__AlreadyInitializedWrappedCollection();

    bool private _wrappedCollectionInitialized;

    function initializeWrappedCollectionAddress(address wrappedCollectionAddress_) public {
        _requireCallerIsContractOwner();

        if(_wrappedCollectionInitialized) {
            revert AdventureERC721CWInitializable__AlreadyInitializedWrappedCollection();
        }

        _wrappedCollectionInitialized = true;

        _setWrappedCollectionAddress(wrappedCollectionAddress_);
    }
    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorTokenWrapperERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function _requireCallerIsVerifiedEOA() internal view virtual override {
        ICreatorTokenTransferValidator transferValidator_ = getTransferValidator();
        if (address(transferValidator_) != address(0)) {
            if (!transferValidator_.isVerifiedEOA(_msgSender())) {
                revert ERC721WrapperBase__CallerSignatureNotVerifiedInEOARegistry();
            }
        }
    }

    function _doTokenMint(address to, uint256 tokenId) internal virtual override {
        _mint(to, tokenId);
    }

    function _doTokenBurn(uint256 tokenId) internal virtual override {
        _burn(tokenId);
    }

    function _getOwnerOfToken(uint256 tokenId) internal view virtual override returns (address) {
        return ownerOf(tokenId);
    }

    function _tokenExists(uint256 tokenId) internal view virtual override returns (bool) {
        return _exists(tokenId);
    }
}
