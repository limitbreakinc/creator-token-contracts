// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../EOAOnlyCreatorERC721.sol";

/**
 * @title EOAOnlyTimeLockedUnstakeCreatorERC721
 * @author Limit Break, Inc.
 * @notice Extension of EOAOnlyCreatorERC721 that enforces a time lock to unstake the wrapped token.
 */
abstract contract EOAOnlyTimeLockedUnstakeCreatorERC721 is EOAOnlyCreatorERC721 {

    error TimelockHasNotExpired();
    
    /// @dev The amount of time the token is locked before unstaking is permitted.  This cannot be modified after contract creation.
    uint256 immutable private timelockSeconds;

    /// @dev Mapping of token ids to the timestamps when they were staked.
    mapping (uint256 => uint256) private stakedTimestamps;

    constructor(uint256 timelockSeconds_, address wrappedCollectionAddress_, string memory name_, string memory symbol_) CreatorERC721(wrappedCollectionAddress_, name_, symbol_) {
        timelockSeconds = timelockSeconds_;
    }

    /// @notice Returns the timelock duration, in seconds.
    function getTimelockSeconds() external view returns (uint256) {
        return timelockSeconds;
    }

    /// @notice Returns the timestamp at which the specified token id was staked.
    function getStakedTimestamp(uint256 tokenId) external view returns (uint256) {
        return stakedTimestamps[tokenId];
    }

    /// @notice Unstakeable after timelock elapses
    function canUnstake(uint256 tokenId) public virtual view override returns (bool) {
        return super.canUnstake(tokenId) && timelockSeconds <= block.timestamp - stakedTimestamps[tokenId];
    }

    /// @dev Records the block timestamp when the token was staked.
    function _onStake(uint256 tokenId, uint256 value) internal virtual override {
        super._onStake(tokenId, value);

        stakedTimestamps[tokenId] = block.timestamp;
    }

    /// @dev Reverts if the unstaking timelock has not expired.
    function _onUnstake(uint256 tokenId, uint256 value) internal virtual override {
        super._onUnstake(tokenId, value);

        uint256 elapsedTimeSinceStake;
        unchecked {
            elapsedTimeSinceStake = block.timestamp - stakedTimestamps[tokenId];
        }

        if(elapsedTimeSinceStake < timelockSeconds) {
            revert TimelockHasNotExpired();
        }

        delete stakedTimestamps[tokenId];
    }
}
