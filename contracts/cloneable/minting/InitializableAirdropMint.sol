// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InitializableMaxSupplyBase.sol";

/**
 * @title AirdropMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with airdrop minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract InitializableAirdropMint is InitializableMaxSupplyBase {

    error InitializableAirdropMint__AirdropBatchSizeMustBeGreaterThanZero();
    error InitializableAirdropMint__CannotMintToZeroAddress();
    error InitializableAirdropMint__MaxAirdropSupplyAlreadyInitialized();
    error InitializableAirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
    error InitializableAirdropMint__MaxAirdropSupplyCannotBeSetToZero();
    error InitializableAirdropMint__MaxAirdropSupplyExceeded();

    /// @dev The current amount of tokens mintable via airdrop.
    uint256 private _remainingAirdropSupply;

    /// @dev Flag indicating that the airdrop max supply has been initialized.
    bool private _airdropSupplyInitialized;

    /// @dev Initializes parameters of tokens with maximum supplies.
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Throws if _maxAirdropSupply has already been set to a non-zero value.
    /// Throws if specified maxSupply_ is zero.
    /// Throws if specified maxSupply_ is set to max uint256.
    function initializeMaxAirdropSupply(uint256 maxAirdropMints) public onlyOwner {
        if(_airdropSupplyInitialized) {
            revert InitializableAirdropMint__MaxAirdropSupplyAlreadyInitialized();
        }

        if(maxAirdropMints == 0) {
            revert InitializableAirdropMint__MaxAirdropSupplyCannotBeSetToZero();
        }

        if(maxAirdropMints == type(uint256).max) {
            revert InitializableAirdropMint__MaxAirdropSupplyCannotBeSetToMaxUint256();
        }

        _initializeNextTokenIdCounter();
        _airdropSupplyInitialized = true;
        _remainingAirdropSupply = maxAirdropMints;
    }

    /// @notice Owner bulk mint to airdrop.
    /// Throws if length of `to` array is zero.
    /// Throws if minting batch would exceed the max supply.
    function airdropMint(address[] calldata to) external onlyOwner {
        uint256 batchSize = to.length;
        if(batchSize == 0) {
            revert InitializableAirdropMint__AirdropBatchSizeMustBeGreaterThanZero();
        }
        uint256 currentMintedSupply = mintedSupply();
        if(batchSize > _remainingAirdropSupply) {
            revert InitializableAirdropMint__MaxAirdropSupplyExceeded();
        }
        _requireLessThanMaxSupply(currentMintedSupply + batchSize);

        unchecked {
            uint256 tokenIdToMint = currentMintedSupply + 1;

            _remainingAirdropSupply -= batchSize;
            _advanceNextTokenIdCounter(batchSize);

            for(uint256 i = 0; i < batchSize; ++i) {
                address recipient = to[i];

                if(recipient == address(0)) {
                    revert InitializableAirdropMint__CannotMintToZeroAddress();
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