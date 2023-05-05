// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MaxSupplyBase.sol";

/**
 * @title AirdropMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with airdrop minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract AirdropMint is MaxSupplyBase {

    error AirdropMint__AirdropBatchSizeMustBeGreaterThanZero();
    error AirdropMint__CannotMintToZeroAddress();
    error AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
    error AirdropMint__MaxAirdropSupplyCannotBeSetToZero();
    error AirdropMint__MaxAirdropSupplyExceeded();

    /// @dev The current amount of tokens mintable via airdrop.
    uint256 private _remainingAirdropSupply;

    constructor(
        uint256 maxAirdropMints_,
        uint256 maxSupply_, 
        uint256 maxOwnerMints_) MaxSupplyBase(maxSupply_, maxOwnerMints_) {
        
        if(maxAirdropMints_ == 0) {
            revert AirdropMint__MaxAirdropSupplyCannotBeSetToZero();
        }

        if(maxAirdropMints_ == type(uint256).max) {
            revert AirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
        }

        _remainingAirdropSupply = maxAirdropMints_;
    }

    /// @notice Owner bulk mint to airdrop.
    /// Throws if length of `to` array is zero.
    /// Throws if minting batch would exceed the max supply.
    function airdropMint(address[] calldata to) external onlyOwner {
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
}