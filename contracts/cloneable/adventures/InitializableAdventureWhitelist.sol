// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../adventures/IAdventure.sol";
import "../access/InitializableOwnable.sol";

/**
 * @title AdventureWhitelist
 * @author Limit Break, Inc.
 * @notice Implements the basic security features of the {IAdventurous} token standard for ERC721-compliant tokens.
 * This includes a whitelist for trusted Adventure contracts designed to interoperate with this token.
 */
abstract contract InitializableAdventureWhitelist is InitializableOwnable {

    error InitializableAdventureWhitelist__AdventureIsStillWhitelisted();
    error InitializableAdventureWhitelist__AlreadyWhitelisted();
    error InitializableAdventureWhitelist__ArrayIndexOverflowsUint128();
    error InitializableAdventureWhitelist__CallerNotAWhitelistedAdventure();
    error InitializableAdventureWhitelist__InvalidAdventureContract();
    error InitializableAdventureWhitelist__NotWhitelisted();

    struct AdventureDetails {
        bool isWhitelisted;
        uint128 arrayIndex;
    }

    /// @dev Emitted when the adventure whitelist is updated
    event AdventureWhitelistUpdated(address indexed adventure, bool whitelisted);
    
    /// @dev Whitelist array for iteration
    address[] public whitelistedAdventureList;

    /// @dev Whitelist mapping
    mapping (address => AdventureDetails) public whitelistedAdventures;

    /// @notice Returns whether the specified account is a whitelisted adventure
    function isAdventureWhitelisted(address account) public view returns (bool) {
        return whitelistedAdventures[account].isWhitelisted;
    }

    /// @notice Whitelists an adventure and specifies whether or not the quests in that adventure lock token transfers
    /// Throws when the adventure is already in the whitelist.
    /// Throws when the specified address does not implement the IAdventure interface.
    ///
    /// Postconditions:
    /// The specified adventure contract is in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function whitelistAdventure(address adventure) external onlyOwner {
        if(isAdventureWhitelisted(adventure)) {
            revert InitializableAdventureWhitelist__AlreadyWhitelisted();
        }

        if(!IERC165(adventure).supportsInterface(type(IAdventure).interfaceId)) {
            revert InitializableAdventureWhitelist__InvalidAdventureContract();
        }

        uint256 arrayIndex = whitelistedAdventureList.length;
        if(arrayIndex > type(uint128).max) {
            revert InitializableAdventureWhitelist__ArrayIndexOverflowsUint128();
        }

        whitelistedAdventures[adventure].isWhitelisted = true;
        whitelistedAdventures[adventure].arrayIndex = uint128(arrayIndex);
        whitelistedAdventureList.push(adventure);

        emit AdventureWhitelistUpdated(adventure, true);
    }

    /// @notice Removes an adventure from the whitelist
    /// Throws when the adventure is not in the whitelist.
    ///
    /// Postconditions:
    /// The specified adventure contract is no longer in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function unwhitelistAdventure(address adventure) external onlyOwner {
        if(!isAdventureWhitelisted(adventure)) {
            revert InitializableAdventureWhitelist__NotWhitelisted();
        }
        
        uint128 itemPositionToDelete = whitelistedAdventures[adventure].arrayIndex;
        uint256 arrayEndIndex = whitelistedAdventureList.length - 1;
        if(itemPositionToDelete != arrayEndIndex) {
            whitelistedAdventureList[itemPositionToDelete] = whitelistedAdventureList[arrayEndIndex];
            whitelistedAdventures[whitelistedAdventureList[itemPositionToDelete]].arrayIndex = itemPositionToDelete;
        }

        whitelistedAdventureList.pop();
        delete whitelistedAdventures[adventure];

        emit AdventureWhitelistUpdated(adventure, false);
    }

    /// @dev Validates that the caller is a whitelisted adventure
    /// Throws when the caller is not in the adventure whitelist.
    function _requireCallerIsWhitelistedAdventure() internal view {
        if(!isAdventureWhitelisted(_msgSender())) {
            revert InitializableAdventureWhitelist__CallerNotAWhitelistedAdventure();
        }
    }

    /// @dev Validates that the specified adventure has been removed from the whitelist
    /// to prevent early backdoor exiting from adventures.
    /// Throws when specified adventure is still whitelisted.
    function _requireAdventureRemovedFromWhitelist(address adventure) internal view {
        if(isAdventureWhitelisted(adventure)) {
            revert InitializableAdventureWhitelist__AdventureIsStillWhitelisted();
        }
    }
}
