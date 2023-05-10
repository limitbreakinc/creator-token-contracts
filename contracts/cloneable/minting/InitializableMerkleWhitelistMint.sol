// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InitializableClaimPeriodBase.sol";
import "./InitializableMaxSupplyBase.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleWhitelistMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with merkle-proof based whitelist minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken`.
 */
abstract contract InitializableMerkleWhitelistMint is InitializableClaimPeriodBase, InitializableMaxSupplyBase {

    error InitializableMerkleWhitelistMint__AddressHasAlreadyClaimed();
    error InitializableMerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints();
    error InitializableMerkleWhitelistMint__InvalidProof();
    error InitializableMerkleWhitelistMint__MaxMintsMustBeGreaterThanZero();
    error InitializableMerkleWhitelistMint__MerkleRootAlreadyInitialized();
    error InitializableMerkleWhitelistMint__MerkleRootCannotBeZero();
    error InitializableMerkleWhitelistMint__MerkleRootHasNotBeenInitialized();
    error InitializableMerkleWhitelistMint__MerkleRootImmutable();

    /// @dev Boolean flag to enable the ability to update the merkle root
    bool private _merkleRootChangeable;

    /// @dev This is the root ERC-721 contract from which claims can be made
    bytes32 private _merkleRoot;

    /// @dev This is the current amount of tokens mintable via merkle whitelist claims
    uint256 private _remainingMerkleMints;

    /// @dev Mapping that tracks whether or not an address has claimed their whitelist mint
    mapping (address => bool) private whitelistClaimed;

    /// @notice Emitted when a merkle root is updated
    event MerkleRootUpdated(bytes32 merkleRoot_);

    /// @dev Initializes the merkle root containing the whitelist.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the merkle root has already been initialized.
    /// Throws when the specified merkle root is zero.
    function initializeMerkleRoot(bytes32 merkleRoot_, uint256 maxMerkleMints_, bool merkleRootChangeable_) public onlyOwner {
        if(_merkleRoot != bytes32(0)) {
            revert InitializableMerkleWhitelistMint__MerkleRootAlreadyInitialized();
        }

        if(merkleRoot_ == bytes32(0)) {
            revert InitializableMerkleWhitelistMint__MerkleRootCannotBeZero();
        }
        
        if(maxMerkleMints_ == 0) {
            revert InitializableMerkleWhitelistMint__MaxMintsMustBeGreaterThanZero();
        }

        _merkleRoot = merkleRoot_;
        _remainingMerkleMints = maxMerkleMints_;

        if(merkleRootChangeable_) {
            _merkleRootChangeable = merkleRootChangeable_;
        }

        _initializeNextTokenIdCounter();
    }

    /// @notice Mints the specified quantity to the calling address if the submitted merkle proof successfully verifies the reserved quantity for the caller in the whitelist.
    ///
    /// Throws when the claim period has not opened.
    /// Throws when the claim period has closed.
    /// Throws if a merkle root has not been set.
    /// Throws if the caller has already successfully claimed.
    /// Throws if the quantity minted plus amount already minted exceeds the maximum amount claimable via merkle root.
    /// Throws if the submitted merkle proof does not successfully verify the reserved quantity for the caller.
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof_) external {
        _requireClaimsOpen();

        bytes32 merkleRootCache = _merkleRoot;

        if(merkleRootCache == bytes32(0)) {
            revert InitializableMerkleWhitelistMint__MerkleRootHasNotBeenInitialized();
        }

        if(whitelistClaimed[_msgSender()]) {
            revert InitializableMerkleWhitelistMint__AddressHasAlreadyClaimed();
        }

        uint256 supplyAfterMint = mintedSupply() + quantity;

        if(quantity > _remainingMerkleMints) {
            revert InitializableMerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints();
        }
        _requireLessThanMaxSupply(supplyAfterMint);

        if(!MerkleProof.verify(merkleProof_, merkleRootCache, keccak256(abi.encodePacked(_msgSender(), quantity)))) {
            revert InitializableMerkleWhitelistMint__InvalidProof();
        }

        whitelistClaimed[_msgSender()] = true;

        unchecked {
            _remainingMerkleMints -= quantity;
        }

        _mintBatch(_msgSender(), quantity);
    }

    /// @notice Update the merkle root if the merkle root was marked as changeable during initialization
    ///
    /// Throws if the `merkleRootChangable` boolean is false
    /// Throws if provided merkle root is 0
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        if(!_merkleRootChangeable) {
            revert InitializableMerkleWhitelistMint__MerkleRootImmutable();
        }

        if(merkleRoot_ == bytes32(0)) {
            revert InitializableMerkleWhitelistMint__MerkleRootCannotBeZero();
        }

        _merkleRoot = merkleRoot_;

        emit MerkleRootUpdated(merkleRoot_);
    }

    /// @notice Returns the merkle root
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @notice Returns the remaining amount of token mints via merkle claiming
    function remainingMerkleMints() external view returns (uint256) {
        return _remainingMerkleMints;
    }

    /// @notice Returns true if the account already claimed their whitelist mint, false otherwise
    function isWhitelistClaimed(address account) external view returns (bool) {
        return whitelistClaimed[account];
    }
}