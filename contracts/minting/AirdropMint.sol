// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MaxSupply.sol";

/**
 * @title AirdropMintBase
 * @author Limit Break, Inc.
 * @notice Base functionality of a contract mix-in that may optionally be used with extend ERC-721 tokens with airdrop minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract AirdropMintBase is MaxSupplyBase {

    error AirdropMint__AirdropBatchSizeMustBeGreaterThanZero();
    error AirdropMint__CannotMintToZeroAddress();
    error AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
    error AirdropMint__MaxAirdropSupplyCannotBeSetToZero();
    error AirdropMint__MaxAirdropSupplyExceeded();

    /// @dev The current amount of tokens mintable via airdrop.
    uint256 private _remainingAirdropSupply;

    /// @notice Owner bulk mint to airdrop.
    /// Throws if length of `to` array is zero.
    /// Throws if minting batch would exceed the max supply.
    function airdropMint(address[] calldata to) external {
        _requireCallerIsContractOwner();

        uint256 batchSize = to.length;
        if(batchSize == 0) {
            revert AirdropMint__AirdropBatchSizeMustBeGreaterThanZero();
        }
        uint256 currentMintedSupply = mintedSupply();
        if(batchSize > _remainingAirdropSupply) {
            revert AirdropMint__MaxAirdropSupplyExceeded();
        }
        _requireLessThanMaxSupply(currentMintedSupply + batchSize);

        unchecked {
            uint256 tokenIdToMint = currentMintedSupply + 1;

            _remainingAirdropSupply -= batchSize;
            _advanceNextTokenIdCounter(batchSize);

            for(uint256 i = 0; i < batchSize; ++i) {
                address recipient = to[i];

                if(recipient == address(0)) {
                    revert AirdropMint__CannotMintToZeroAddress();
                }

                _mintToken(to[i], tokenIdToMint + i);
            }
        }
    }

    /// @notice Returns the remaining amount of tokens mintable via airdrop
    function remainingAirdropSupply() public view returns (uint256) {
        return _remainingAirdropSupply;
    }

    function _setMaxAirdropSupply(uint256 maxAirdropMints_) internal {
        if(maxAirdropMints_ == 0) {
            revert AirdropMint__MaxAirdropSupplyCannotBeSetToZero();
        }

        if(maxAirdropMints_ == type(uint256).max) {
            revert AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
        }

        _remainingAirdropSupply = maxAirdropMints_;

        _initializeNextTokenIdCounter();
    }
}

/**
 * @title AirdropMint
 * @author Limit Break, Inc.
 * @notice Constructable AirdropMint Contract implementation.
 */
abstract contract AirdropMint is AirdropMintBase, MaxSupply {
    constructor(uint256 maxAirdropMints_) {
        _setMaxAirdropSupply(maxAirdropMints_);
    }

    function maxSupply() public view override(MaxSupplyBase, MaxSupply) returns (uint256) {
        return _maxSupplyImmutable;
    }
}

/**
 * @title AirdropMintInitializable
 * @author Limit Break, Inc.
 * @notice Initializable AirdropMint Contract implementation to allow for EIP-1167 clones.
 */
abstract contract AirdropMintInitializable is AirdropMintBase, MaxSupplyInitializable {

    error AirdropMintInitializable__MaxAirdropSupplyAlreadyInitialized();
    
    /// @dev Flag indicating that the airdrop max supply has been initialized.
    bool private _airdropSupplyInitialized;

    function initializeMaxAirdropSupply(uint256 maxAirdropMints_) public {
        _requireCallerIsContractOwner();

        if(_airdropSupplyInitialized) {
            revert AirdropMintInitializable__MaxAirdropSupplyAlreadyInitialized();
        }

        _airdropSupplyInitialized = true;

        _setMaxAirdropSupply(maxAirdropMints_);
    }
}