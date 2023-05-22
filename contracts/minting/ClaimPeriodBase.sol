// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/OwnablePermissions.sol";

/**
 * @title ClaimPeriodBase
 * @author Limit Break, Inc.
 * @notice In order to support multiple contracts with enforced claim periods, the claim period has been moved to this base contract.
 *
 */
abstract contract ClaimPeriodBase is OwnablePermissions {

    error ClaimPeriodBase__ClaimsMustBeClosedToReopen();
    error ClaimPeriodBase__ClaimPeriodIsNotOpen();
    error ClaimPeriodBase__ClaimPeriodMustBeClosedInTheFuture();

    /// @dev True if claims have been initalized, false otherwise.
    bool private claimPeriodInitialized;

    /// @dev The timestamp when the claim period closes - when this value is zero and claims are open, the claim period is open indefinitely
    uint256 private claimPeriodClosingTimestamp;

    /// @dev Emitted when a claim period is scheduled to be closed.
    event ClaimPeriodClosing(uint256 claimPeriodClosingTimestamp);

    /// @dev Emitted when a claim period is scheduled to be opened.
    event ClaimPeriodOpened(uint256 claimPeriodClosingTimestamp);

    /// @dev Opens the claim period.  Claims can be closed with a custom amount of warning time using the closeClaims function.
    /// Accepts a claimPeriodClosingTimestamp_ timestamp which will open the period ending at that time (in seconds)
    /// NOTE: Use as high a window as possible to prevent gas wars for claiming
    /// For an unbounded claim window, pass in type(uint256).max
    function openClaims(uint256 claimPeriodClosingTimestamp_) external {
        _requireCallerIsContractOwner();

        if(claimPeriodClosingTimestamp_ <= block.timestamp) {
            revert ClaimPeriodBase__ClaimPeriodMustBeClosedInTheFuture();
        }

        _onClaimPeriodOpening();

        if(claimPeriodInitialized) {
            if(block.timestamp < claimPeriodClosingTimestamp) {
                revert ClaimPeriodBase__ClaimsMustBeClosedToReopen();
            }
        } else {
            claimPeriodInitialized = true;
        }

        claimPeriodClosingTimestamp = claimPeriodClosingTimestamp_;

        emit ClaimPeriodOpened(claimPeriodClosingTimestamp_);
    }

    /// @dev Closes claims at a specified timestamp.
    ///
    /// Throws when the specified timestamp is not in the future.
    function closeClaims(uint256 claimPeriodClosingTimestamp_) external {
        _requireCallerIsContractOwner();

        _requireClaimsOpen();

        if(claimPeriodClosingTimestamp_ <= block.timestamp) {
            revert ClaimPeriodBase__ClaimPeriodMustBeClosedInTheFuture();
        }

        claimPeriodClosingTimestamp = claimPeriodClosingTimestamp_;
        
        emit ClaimPeriodClosing(claimPeriodClosingTimestamp_);
    }

    /// @dev Returns the Claim Period Timestamp
    function getClaimPeriodClosingTimestamp() external view returns (uint256) {
        return claimPeriodClosingTimestamp;
    }

    /// @notice Returns true if the claim period has been opened, false otherwise
    function isClaimPeriodOpen() external view returns (bool) {
        return _isClaimPeriodOpen();
    }

    /// @dev Returns true if claim period is open, false otherwise.
    function _isClaimPeriodOpen() internal view returns (bool) {
        return claimPeriodInitialized && block.timestamp < claimPeriodClosingTimestamp;
    }

    /// @dev Validates that the claim period is open.
    /// Throws if claims are not open.
    function _requireClaimsOpen() internal view {
        if(!_isClaimPeriodOpen()) {
            revert ClaimPeriodBase__ClaimPeriodIsNotOpen();
        }
    }

    /// @dev Hook to allow inheriting contracts to perform state validation when opening the claim period
    function _onClaimPeriodOpening() internal virtual {}
}