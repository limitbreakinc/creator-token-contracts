// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MintTokenBase.sol";
import "./SequentialMintBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MaxSupplyBase
 * @author Limit Break, Inc.
 * @notice In order to support multiple contracts with a global maximum supply, the max supply has been moved to this base contract.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract MaxSupplyBase is Ownable, MintTokenBase, SequentialMintBase {

    error MaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints();
    error MaxSupplyBase__CannotMintToAddressZero();
    error MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
    error MaxSupplyBase__MaxSupplyExceeded();
    error MaxSupplyBase__MintedQuantityMustBeGreaterThanZero();

    /// @dev The global maximum supply for a contract.  Inheriting contracts must reference this maximum supply in addition to any other
    /// @dev constraints they are looking to enforce.
    uint256 public immutable maxSupply;

    /// @dev The number of tokens remaining to mint via owner mint.
    uint256 private _remainingOwnerMints;

    /// @dev Emitted when the maximum supply is initialized
    event MaxSupplyInitialized(uint256 maxSupply, uint256 maxOwnerMints);

    constructor(uint256 maxSupply_, uint256 maxOwnerMints_) {
        if(maxSupply_ == type(uint256).max) {
            revert MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
        }

        maxSupply = maxSupply_;
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
            revert MaxSupplyBase__CannotMintToAddressZero();
        }

        if(quantity > _remainingOwnerMints) {
            revert MaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints();
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

    function mintedSupply() public view returns (uint256) {
        return getNextTokenId() - 1;
    }

    function _requireLessThanMaxSupply(uint256 supplyAfterMint) internal view {
        uint256 maxSupplyCache = maxSupply;
        if (maxSupplyCache > 0) {
            if (supplyAfterMint > maxSupplyCache) {
                revert MaxSupplyBase__MaxSupplyExceeded();
            }
        }
    }

    /// @dev Batch mints the specified quantity to the specified address
    /// Throws if quantity is zero
    /// Throws if `to` is a smart contract that does not implement IERC721 receiver
    function _mintBatch(address to, uint256 quantity) internal returns (uint256 startTokenId, uint256 endTokenId) {
        if(quantity == 0) {
            revert MaxSupplyBase__MintedQuantityMustBeGreaterThanZero();
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