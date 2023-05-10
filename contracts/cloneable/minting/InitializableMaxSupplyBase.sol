// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";
import "../../minting/MintTokenBase.sol";
import "../../minting/SequentialMintBase.sol";

/**
 * @title MaxSupplyBase
 * @author Limit Break, Inc.
 * @notice In order to support multiple contracts with a global maximum supply, the max supply has been moved to this base contract.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract InitializableMaxSupplyBase is InitializableOwnable, MintTokenBase, SequentialMintBase {

    error InitializableMaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints();
    error InitializableMaxSupplyBase__CannotMintToAddressZero();
    error InitializableMaxSupplyBase__MaxSupplyAlreadyInitialized();
    error InitializableMaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
    error InitializableMaxSupplyBase__MaxSupplyExceeded();
    error InitializableMaxSupplyBase__MintedQuantityMustBeGreaterThanZero();

    /// @dev The global maximum supply for a contract.  Inheriting contracts must reference this maximum supply in addition to any other
    /// @dev constraints they are looking to enforce.
    uint256 private _maxSupply;

    /// @dev The number of tokens remaining to mint via owner mint.
    uint256 private _remainingOwnerMints;

    /// @dev Boolean value set during initialization to prevent reinitializing the value.
    bool private _maxSupplyInitialized;

    /// @dev Emitted when the maximum supply is initialized
    event MaxSupplyInitialized(uint256 maxSupply, uint256 maxOwnerMints);

    /// @dev Initializes the global maximum supply within an inheriting contract.  
    function initializeMaxSupply(uint256 maxSupply_, uint256 maxOwnerMints_) external onlyOwner {
        if(_maxSupplyInitialized) {
            revert InitializableMaxSupplyBase__MaxSupplyAlreadyInitialized();
        }
        if(maxSupply_ == type(uint256).max) {
            revert InitializableMaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
        }

        _maxSupplyInitialized = true;
        _maxSupply = maxSupply_;
        _remainingOwnerMints = maxOwnerMints_;

        _initializeNextTokenIdCounter();

        emit MaxSupplyInitialized(maxSupply_, maxOwnerMints_);
    }

    /// @notice Mints the specified quantity to the provided address
    ///
    /// Throws when the caller is not the owner
    /// Throws when provided quantity is zero
    /// Throws when provided address is address zero
    /// Throws if the quantity minted plus amount already minted exceeds the maximum amount mintable by the owner
    function ownerMint(address to, uint256 quantity) external onlyOwner {
        if(to == address(0)) {
            revert InitializableMaxSupplyBase__CannotMintToAddressZero();
        }

        if(quantity > _remainingOwnerMints) {
            revert InitializableMaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints();
        }
        _requireLessThanMaxSupply(mintedSupply() + quantity);

        unchecked {
            _remainingOwnerMints -= quantity;
        }
        _mintBatch(to, quantity);
    }

    function remainingOwnerMints() public view returns (uint256) {
        return _remainingOwnerMints;
    }

    /// @dev Returns the Max Supply
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function maxSupplyInitialized() public view returns (bool) {
        return _maxSupplyInitialized;
    }

    function mintedSupply() public view returns (uint256) {
        return getNextTokenId() - 1;
    }

    function _requireLessThanMaxSupply(uint256 supplyAfterMint) internal view {
        uint256 maxSupplyCache = _maxSupply;
        if (maxSupplyCache > 0) {
            if (supplyAfterMint > maxSupplyCache) {
                revert InitializableMaxSupplyBase__MaxSupplyExceeded();
            }
        }
    }

    /// @dev Batch mints the specified quantity to the specified address
    /// Throws if quantity is zero
    /// Throws if `to` is a smart contract that does not implement IERC721 receiver
    function _mintBatch(address to, uint256 quantity) internal returns (uint256 startTokenId, uint256 endTokenId) {
        if(quantity == 0) {
            revert InitializableMaxSupplyBase__MintedQuantityMustBeGreaterThanZero();
        }
        startTokenId = getNextTokenId();
        unchecked {
            endTokenId = startTokenId + quantity - 1;
            _advanceNextTokenIdCounter(quantity);

            for(uint256 i = 0; i < quantity; ++i) {
                _mintToken(to, startTokenId + i);
            }
        }
        return (startTokenId, endTokenId);
    }
}