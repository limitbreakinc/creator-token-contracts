// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CreatorERC721.sol";
import "./utils/EOARegistryAccess.sol";

/**
 * @title EOAOnlyCreatorERC721
 * @author Limit Break, Inc.
 * @notice Extends CreatorERC721, but only permits EOA accounts to stake/wrap tokens.  
 * @dev Take care before using this variant of CreatorERC721. Restricting operations to EOA only accounts can break Defi composability, 
 * so if Defi composability is an objective, this is not a good option.  Be advised that in the future, EOA accounts might not be a thing
 * but this is yet to be determined.  See https://eips.ethereum.org/EIPS/eip-4337 for more information.
 */
abstract contract EOAOnlyCreatorERC721 is CreatorERC721, EOARegistryAccess {

    error SignatureNotVerifiedInEOARegistry(address account, address eoaRegistry);
    error SmartContractsNotPermittedToStake();

    /// @notice Allows holders of the wrapped ERC721 token to stake into this enhanced ERC721 token.
    /// The out of the box enhancement is the capability enabled by the whitelisted transfer system.
    /// Developers can extend the functionality of this contract with additional powered up features.
    ///
    /// Throws when caller does not own the token id on the wrapped collection.
    /// Throws when caller is a smart contract.
    /// Throws when inheriting contract reverts in the _onStake function (for example, in a pay to stake scenario).
    /// Throws when _mint function reverts (for example, when additional mint validation logic reverts).
    /// Throws when transferFrom function reverts (for example, if this contract does not have approval to transfer token).
    /// 
    /// Postconditions:
    /// ---------------
    /// The staker's token is now owned by this contract.
    /// The staker has received a wrapper token on this contract with the same token id.
    /// A `Staked` event has been emitted.
    function stake(uint256 tokenId) public virtual payable override {
        IEOARegistry eoaVerificationRegistry = getEOARegistry();
        if(address(eoaVerificationRegistry) == address(0)) {
            if(_msgSender() != tx.origin) {
                revert SmartContractsNotPermittedToStake();
            }
        } else {
            if(!eoaVerificationRegistry.isVerifiedEOA(_msgSender())) {
                revert SignatureNotVerifiedInEOARegistry(_msgSender(), address(eoaVerificationRegistry));
            }
        }

        super.stake(tokenId);
    }
}
