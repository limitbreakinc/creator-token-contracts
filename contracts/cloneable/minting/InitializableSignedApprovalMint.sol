// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InitializableMaxSupplyBase.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
* @title SignedApprovalMint
* @author Limit Break, Inc.
* @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with Signed Approval minting capabilities, allowing an approved signer to issue a limited amount of mints.
* @dev Inheriting contracts must implement `_mintToken`.
*/
abstract contract InitializableSignedApprovalMint is InitializableMaxSupplyBase, EIP712 {

    error InitializableSignedApprovalMint__AddressAlreadyMinted();
    error InitializableSignedApprovalMint__InvalidSignature();
    error InitializableSignedApprovalMint__MaxQuantityMustBeGreaterThanZero();
    error InitializableSignedApprovalMint__MintExceedsMaximumAmountBySignedApproval();
    error InitializableSignedApprovalMint__SignedClaimsAreDecommissioned();
    error InitializableSignedApprovalMint__SignerAlreadyInitialized();
    error InitializableSignedApprovalMint__SignerCannotBeInitializedAsAddressZero();
    error InitializableSignedApprovalMint__SignerIsAddressZero();

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
            revert InitializableSignedApprovalMint__AddressAlreadyMinted();
        }

        if (_approvalSigner == address(0)) { 
            revert InitializableSignedApprovalMint__SignerIsAddressZero();
        }

        _requireSignedClaimsActive();

        if (quantity > _remainingSignedMints) {
            revert InitializableSignedApprovalMint__MintExceedsMaximumAmountBySignedApproval();
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
            revert InitializableSignedApprovalMint__InvalidSignature();
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
    function decommissionSignedApprovals() external onlyOwner {
        _requireSignedClaimsActive();
        _signedClaimsDecommissioned = true;
        emit SignedClaimsDecommissioned();
    }

    /// @dev Initializes the signer address for signed approvals
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    ///
    /// Throws when called by non-owner of contract.
    /// Throws when the signer has already been initialized.
    /// Throws when the provided signer is address(0).
    /// Throws when maxQuantity = 0
    function initializeSigner(address signer, uint256 maxQuantity) public onlyOwner {
        if(_approvalSigner != address(0)) {
            revert InitializableSignedApprovalMint__SignerAlreadyInitialized();
        }
        if(signer == address(0)) {
            revert InitializableSignedApprovalMint__SignerCannotBeInitializedAsAddressZero();
        }
        if(maxQuantity == 0) {
            revert InitializableSignedApprovalMint__MaxQuantityMustBeGreaterThanZero();
        }
        _initializeNextTokenIdCounter();
        _approvalSigner = signer;
        _remainingSignedMints = maxQuantity;
    }

    /// @dev Allows signer to update the signer address
    /// This allows the signer to set new signer to address(0) to prevent future allowed mints
    /// NOTE: Setting signer to address(0) is irreversible - approvals will be disabled permanently and all outstanding signatures will be invalid.
    ///
    /// Throws when caller is not owner
    /// Throws when current signer is address(0)
    function setSigner(address newSigner) public onlyOwner {
        if(_signedClaimsDecommissioned) {
            revert InitializableSignedApprovalMint__SignedClaimsAreDecommissioned();
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
            revert InitializableSignedApprovalMint__SignedClaimsAreDecommissioned();
        }
    }
}