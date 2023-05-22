// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/OwnablePermissions.sol";
import "./MintTokenBase.sol";
import "./SequentialMintBase.sol";

/**
 * @title MaxSupplyBase
 * @author Limit Break, Inc.
 * @notice In order to support multiple contracts with a global maximum supply, the max supply has been moved to this base contract.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract MaxSupplyBase is OwnablePermissions, MintTokenBase, SequentialMintBase {

    error MaxSupplyBase__CannotClaimMoreThanMaximumAmountOfOwnerMints();
    error MaxSupplyBase__CannotMintToAddressZero();
    error MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
    error MaxSupplyBase__MaxSupplyExceeded();
    error MaxSupplyBase__MintedQuantityMustBeGreaterThanZero();

    /// @dev The global maximum supply for a contract.  Inheriting contracts must reference this maximum supply in addition to any other
    /// @dev constraints they are looking to enforce.
    /// @dev If `_maxSupply` is set to zero, the global max supply will match the combined max allowable mints for each minting mix-in used.
    /// @dev If the `_maxSupply` is below the total sum of allowable mints, the `_maxSupply` will be prioritized.
    uint256 private _maxSupply;

    /// @dev The number of tokens remaining to mint via owner mint.
    /// @dev This can be used to guarantee minting out by allowing the owner to mint unclaimed supply after the public mint is completed.
    uint256 private _remainingOwnerMints;

    /// @dev Emitted when the maximum supply is initialized
    event MaxSupplyInitialized(uint256 maxSupply, uint256 maxOwnerMints);

    /// @notice Mints the specified quantity to the provided address
    ///
    /// Throws when the caller is not the owner
    /// Throws when provided quantity is zero
    /// Throws when provided address is address zero
    /// Throws if the quantity minted plus amount already minted exceeds the maximum amount mintable by the owner
    function ownerMint(address to, uint256 quantity) external {
        _requireCallerIsContractOwner();

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

    function maxSupply() public virtual view returns (uint256) {
        return _maxSupply;
    }

    function remainingOwnerMints() public view returns (uint256) {
        return _remainingOwnerMints;
    }

    function mintedSupply() public view returns (uint256) {
        return getNextTokenId() - 1;
    }

    function _setMaxSupplyAndOwnerMints(uint256 maxSupply_, uint256 maxOwnerMints_) internal {
        if(maxSupply_ == type(uint256).max) {
            revert MaxSupplyBase__MaxSupplyCannotBeSetToMaxUint256();
        }

        _maxSupply = maxSupply_;
        _remainingOwnerMints = maxOwnerMints_;

        _initializeNextTokenIdCounter();

        emit MaxSupplyInitialized(maxSupply_, maxOwnerMints_);
    }

    function _requireLessThanMaxSupply(uint256 supplyAfterMint) internal view {
        uint256 maxSupplyCache = maxSupply();
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

/**
 * @title MaxSupply
 * @author Limit Break, Inc.
 * @notice Constructable implementation of the MaxSupplyBase mixin.
 */
abstract contract MaxSupply is MaxSupplyBase {

    uint256 internal immutable _maxSupplyImmutable;

    constructor(uint256 maxSupply_, uint256 maxOwnerMints_) {
        _setMaxSupplyAndOwnerMints(maxSupply_, maxOwnerMints_);
        _maxSupplyImmutable = maxSupply_;
    }

    function maxSupply() public virtual view override returns (uint256) {
        return _maxSupplyImmutable;
    }
}

/**
 * @title MaxSupplyInitializable
 * @author Limit Break, Inc.
 * @notice Initializable implementation of the MaxSupplyBase mixin to allow for EIP-1167 clones.
 */
abstract contract MaxSupplyInitializable is MaxSupplyBase {

    error InitializableMaxSupplyBase__MaxSupplyAlreadyInitialized();

    /// @dev Boolean value set during initialization to prevent reinitializing the value.
    bool private _maxSupplyInitialized;

    function initializeMaxSupply(uint256 maxSupply_, uint256 maxOwnerMints_) external {
        _requireCallerIsContractOwner();

        if(_maxSupplyInitialized) {
            revert InitializableMaxSupplyBase__MaxSupplyAlreadyInitialized();
        }

        _maxSupplyInitialized = true;

        _setMaxSupplyAndOwnerMints(maxSupply_, maxOwnerMints_);        
    }

    function maxSupplyInitialized() public view returns (bool) {
        return _maxSupplyInitialized;
    }
}
