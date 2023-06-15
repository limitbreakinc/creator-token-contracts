// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ClaimPeriodBase.sol";
import "./MaxSupply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleWhitelistMint
 * @author Limit Break, Inc.
 * @notice Base functionality of a contract mix-in that may optionally be used with extend ERC-721 tokens with merkle-proof based whitelist minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken`.
 *
 * @dev The leaf nodes of the merkle tree contain the address and quantity of tokens that may be minted by that address.
 *      Duplicate addresses are not permitted.  For instance, address(Bob) may only appear once in the merkle tree.
 *      If address(Bob) appears more than once, Bob will be able to claim from only one of the leaves that contain his 
 *      address. In the event a mistake is made and duplicates are included in the merkle tree, the owner of the 
 *      contract may be able to de-duplicate the tree and submit a new root, provided 
 *      `_remainingNumberOfMerkleRootChanges` is greater than 0. The number of permitted merkle root changes is set 
 *      during contract construction/initialization, so take this into account when deploying your contracts.
 */
abstract contract MerkleWhitelistMintBase is ClaimPeriodBase, MaxSupplyBase {
    error MerkleWhitelistMint__AddressHasAlreadyClaimed();
    error MerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints();
    error MerkleWhitelistMint__InvalidProof();
    error MerkleWhitelistMint__MaxMintsMustBeGreaterThanZero();
    error MerkleWhitelistMint__MerkleRootCannotBeZero();
    error MerkleWhitelistMint__MerkleRootHasNotBeenInitialized();
    error MerkleWhitelistMint__MerkleRootImmutable();
    error MerkleWhitelistMint__PermittedNumberOfMerkleRootChangesMustBeGreaterThanZero();

    /// @dev The number of times the merkle root may be updated
    uint256 private _remainingNumberOfMerkleRootChanges;

    /// @dev This is the root ERC-721 contract from which claims can be made
    bytes32 private _merkleRoot;

    /// @dev This is the current amount of tokens mintable via merkle whitelist claims
    uint256 private _remainingMerkleMints;

    /// @dev Mapping that tracks whether or not an address has claimed their whitelist mint
    mapping (address => bool) private whitelistClaimed;

    /// @notice Emitted when a merkle root is updated
    event MerkleRootUpdated(bytes32 merkleRoot_);

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
            revert MerkleWhitelistMint__MerkleRootHasNotBeenInitialized();
        }

        if(whitelistClaimed[_msgSender()]) {
            revert MerkleWhitelistMint__AddressHasAlreadyClaimed();
        }

        uint256 supplyAfterMint = mintedSupply() + quantity;

        if(quantity > _remainingMerkleMints) {
            revert MerkleWhitelistMint__CannotClaimMoreThanMaximumAmountOfMerkleMints();
        }
        _requireLessThanMaxSupply(supplyAfterMint);

        if(!MerkleProof.verify(merkleProof_, merkleRootCache, keccak256(abi.encodePacked(_msgSender(), quantity)))) {
            revert MerkleWhitelistMint__InvalidProof();
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
    function setMerkleRoot(bytes32 merkleRoot_) external {
        _requireCallerIsContractOwner();

        if(_remainingNumberOfMerkleRootChanges == 0) {
            revert MerkleWhitelistMint__MerkleRootImmutable();
        }

        if(merkleRoot_ == bytes32(0)) {
            revert MerkleWhitelistMint__MerkleRootCannotBeZero();
        }

        _merkleRoot = merkleRoot_;

        emit MerkleRootUpdated(merkleRoot_);

        unchecked {
            _remainingNumberOfMerkleRootChanges--;
        }
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

    function _setMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges(
        uint256 maxMerkleMints_, 
        uint256 permittedNumberOfMerkleRootChanges_) internal {

        if(maxMerkleMints_ == 0) {
            revert MerkleWhitelistMint__MaxMintsMustBeGreaterThanZero();
        }

        if (permittedNumberOfMerkleRootChanges_ == 0) {
            revert MerkleWhitelistMint__PermittedNumberOfMerkleRootChangesMustBeGreaterThanZero();
        }

        _remainingMerkleMints = maxMerkleMints_;
        _remainingNumberOfMerkleRootChanges = permittedNumberOfMerkleRootChanges_;

        _initializeNextTokenIdCounter();
    }
}

/**
 * @title MerkleWhitelistMint
 * @author Limit Break, Inc.
 * @notice Constructable MerkleWhitelistMint Contract implementation.
 */
abstract contract MerkleWhitelistMint is MerkleWhitelistMintBase, MaxSupply {
    constructor(uint256 maxMerkleMints_, uint256 permittedNumberOfMerkleRootChanges_) {
        _setMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges(
            maxMerkleMints_,
            permittedNumberOfMerkleRootChanges_
        );
    }

    function maxSupply() public view override(MaxSupplyBase, MaxSupply) returns (uint256) {
        return _maxSupplyImmutable;
    }
}

/**
 * @title MerkleWhitelistMintInitializable
 * @author Limit Break, Inc.
 * @notice Initializable MerkleWhitelistMint Contract implementation to allow for EIP-1167 clones. 
 */
abstract contract MerkleWhitelistMintInitializable is MerkleWhitelistMintBase, MaxSupplyInitializable {
    
    error MerkleWhitelistMintInitializable__MerkleSupplyAlreadyInitialized();

    /// @dev Flag indicating that the merkle mint max supply has been initialized.
    bool private _merkleSupplyInitialized;

    function initializeMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges(
        uint256 maxMerkleMints_, 
        uint256 permittedNumberOfMerkleRootChanges_) public {
        _requireCallerIsContractOwner();

        if(_merkleSupplyInitialized) {
            revert MerkleWhitelistMintInitializable__MerkleSupplyAlreadyInitialized();
        }

        _merkleSupplyInitialized = true;

        _setMaxMerkleMintsAndPermittedNumberOfMerkleRootChanges(
            maxMerkleMints_,
            permittedNumberOfMerkleRootChanges_
        );
    }
}