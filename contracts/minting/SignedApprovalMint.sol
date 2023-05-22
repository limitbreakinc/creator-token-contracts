// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MaxSupply.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
* @title SignedApprovalMintBase
* @author Limit Break, Inc.
* @notice Base functionality for a contract mix-in that may optionally be used with extend ERC-721 tokens with Signed Approval minting capabilities, allowing an approved signer to issue a limited amount of mints.
* @dev Inheriting contracts must implement `_mintToken`.
*/
abstract contract SignedApprovalMintBase is MaxSupplyBase, EIP712 {

    error SignedApprovalMint__AddressAlreadyMinted();
    error SignedApprovalMint__InvalidSignature();
    error SignedApprovalMint__MaxQuantityMustBeGreaterThanZero();
    error SignedApprovalMint__MintExceedsMaximumAmountBySignedApproval();
    error SignedApprovalMint__SignedClaimsAreDecommissioned();
    error SignedApprovalMint__SignerCannotBeInitializedAsAddressZero();
    error SignedApprovalMint__SignerIsAddressZero();

    /// @dev Returns true if signed claims have been decommissioned, false otherwise.
    bool private _signedClaimsDecommissioned;

    /// @dev The address of the signer for approved mints.
    address private _approvalSigner;

    /// @dev The remaining amount of tokens mintable via signed approval minting.
    /// NOTE: This is an aggregate of all signers, updating signer will not reset or modify this amount.
    uint256 private _remainingSignedMints;

    /// @dev Mapping of addresses who have already minted 
    mapping(address => bool) private addressMinted;

    /// @dev Emitted when signatures are decommissioned
    event SignedClaimsDecommissioned();

    /// @dev Emitted when a signed mint is claimed
    event SignedMintClaimed(address indexed minter, uint256 startTokenId, uint256 endTokenId);

    /// @dev Emitted when a signer is updated
    event SignerUpdated(address oldSigner, address newSigner); 

    /// @notice Allows a user to claim/mint one or more tokens as approved by the approved signer
    ///
    /// Throws when a signature is invalid.
    /// Throws when the quantity provided does not match the quantity on the signature provided.
    /// Throws when the address has already claimed a token.
    function claimSignedMint(bytes calldata signature, uint256 quantity) external {
        if (addressMinted[_msgSender()]) {
            revert SignedApprovalMint__AddressAlreadyMinted();
        }

        if (_approvalSigner == address(0)) { 
            revert SignedApprovalMint__SignerIsAddressZero();
        }

        _requireSignedClaimsActive();

        if (quantity > _remainingSignedMints) {
            revert SignedApprovalMint__MintExceedsMaximumAmountBySignedApproval();
        }
        _requireLessThanMaxSupply(mintedSupply() + quantity);

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("Approved(address wallet,uint256 quantity)"),
                    _msgSender(),
                    quantity
                )
            )
        );

        if (_approvalSigner != ECDSA.recover(hash, signature)) {
            revert SignedApprovalMint__InvalidSignature();
        }

        addressMinted[_msgSender()] = true;

        unchecked {
            _remainingSignedMints -= quantity;
        }

        (uint256 startTokenId, uint256 endTokenId) = _mintBatch(_msgSender(), quantity);
        emit SignedMintClaimed(_msgSender(), startTokenId, endTokenId);
    }

    /// @notice Decommissions signed approvals
    /// This is a permanent decommissioning, once this is set, no further signatures can be claimed
    ///
    /// Throws if caller is not owner
    /// Throws if already decommissioned
    function decommissionSignedApprovals() external {
        _requireCallerIsContractOwner();
        _requireSignedClaimsActive();
        _signedClaimsDecommissioned = true;
        emit SignedClaimsDecommissioned();
    }

    /// @dev Allows signer to update the signer address
    /// This allows the signer to set new signer to address(0) to prevent future allowed mints
    /// NOTE: Setting signer to address(0) is irreversible - approvals will be disabled permanently and all outstanding signatures will be invalid.
    ///
    /// Throws when caller is not owner
    /// Throws when current signer is address(0)
    function setSigner(address newSigner) public {
        _requireCallerIsContractOwner();

        if(_signedClaimsDecommissioned) {
            revert SignedApprovalMint__SignedClaimsAreDecommissioned();
        }

        emit SignerUpdated(_approvalSigner, newSigner);
        _approvalSigner = newSigner;
    }

    /// @notice Returns true if the provided account has already minted, false otherwise
    function hasMintedBySignedApproval(address account) public view returns (bool) {
        return addressMinted[account];
    }

    /// @notice Returns the address of the approved signer
    function approvalSigner() public view returns (address) {
        return _approvalSigner;
    }

    /// @notice Returns the remaining amount of tokens mintable via signed approvals.
    function remainingSignedMints() public view returns (uint256) {
        return _remainingSignedMints;
    }

    /// @notice Returns true if signed claims have been decommissioned, false otherwise
    function signedClaimsDecommissioned() public view returns (bool) {
        return _signedClaimsDecommissioned;
    }

    /// @dev Internal function used to revert if signed claims are decommissioned.
    function _requireSignedClaimsActive() internal view {
        if(_signedClaimsDecommissioned) {
            revert SignedApprovalMint__SignedClaimsAreDecommissioned();
        }
    }

    function _setSignerAndMaxSignedMintSupply(address signer_, uint256 maxSignedMints_) internal {
        if(signer_ == address(0)) {
            revert SignedApprovalMint__SignerCannotBeInitializedAsAddressZero();
        }

        if(maxSignedMints_ == 0) {
            revert SignedApprovalMint__MaxQuantityMustBeGreaterThanZero();
        }

        _approvalSigner = signer_;
        _remainingSignedMints = maxSignedMints_;

        _initializeNextTokenIdCounter();
    }
}

/**
 * @title SignedApprovalMint
 * @author Limit Break, Inc.
 * @notice Constructable SignedApprovalMint Contract implementation.
 */
abstract contract SignedApprovalMint is SignedApprovalMintBase, MaxSupply {
    constructor(address signer_, uint256 maxSignedMints_) {
        _setSignerAndMaxSignedMintSupply(signer_, maxSignedMints_);
    }

    function maxSupply() public view override(MaxSupplyBase, MaxSupply) returns (uint256) {
        return _maxSupplyImmutable;
    }
}

/**
 * @title SignedApprovalMintInitializable
 * @author Limit Break, Inc.
 * @notice Initializable SignedApprovalMint Contract implementation to allow for EIP-1167 clones. 
 */
abstract contract SignedApprovalMintInitializable is SignedApprovalMintBase, MaxSupplyInitializable {
    
    error SignedApprovalMintInitializable__SignedMintSupplyAlreadyInitialized();

    bool private _signedMintSupplyInitialized;

    function initializeSignerAndMaxSignedMintSupply(address signer_, uint256 maxSignedMints_) public {
        _requireCallerIsContractOwner();

        if(_signedMintSupplyInitialized) {
            revert SignedApprovalMintInitializable__SignedMintSupplyAlreadyInitialized();
        }

        _signedMintSupplyInitialized = true;

        _setSignerAndMaxSignedMintSupply(signer_, maxSignedMints_);
    }
}