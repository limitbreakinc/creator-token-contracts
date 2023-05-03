// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../AdventureERC721C.sol";
import "../../interfaces/ICreatorTokenWrapperERC721.sol";
import "../../utils/WithdrawETH.sol";

/**
 * @title ERC721CW
 * @author Limit Break, Inc.
 * @notice Extends AdventureERC721-C contracts and adds a staking feature used to wrap another ERC721 contract.
 * The wrapper token gives the developer access to the same set of controls present in the ERC721-C standard.
 * in addition to Limit Break's AdventureERC721 staking features.  
 * Holders opt-in to this contract by staking, and it is possible for holders to unstake at the developers' discretion. 
 * The intent of this contract is to allow developers to upgrade existing NFT collections and provide enhanced features.
 *
 * @notice Creators also have discretion to set optional staker constraints should they wish to restrict staking to 
 *         EOA accounts only.
 */
abstract contract AdventureERC721CW is AdventureERC721C, WithdrawETH, ICreatorTokenWrapperERC721 {

    error AdventureERC721CW__CallerNotOwnerOfWrappingToken();
    error AdventureERC721CW__CallerNotOwnerOfWrappedToken();
    error AdventureERC721CW__CallerSignatureNotVerifiedInEOARegistry();
    error AdventureERC721CW__DefaultImplementationOfStakeDoesNotAcceptPayment();
    error AdventureERC721CW__DefaultImplementationOfUnstakeDoesNotAcceptPayment();
    error AdventureERC721CW__InvalidERC721Collection();
    error AdventureERC721CW__SmartContractsNotPermittedToStake();

    /// @dev Points to an external ERC721 contract that will be wrapped via staking.
    IERC721 immutable private wrappedCollection;

    /// @dev The staking constraints that will be used to determine if an address is eligible to stake tokens.
    StakerConstraints private stakerConstraints;

    /// @dev Constructor - specify the name, symbol, and wrapped contract addresses here as well as max number of 
    ///      simultaneous quests per adventure contract.
    constructor(
        address wrappedCollectionAddress_, 
        uint256 maxSimultaneousQuests_,
        string memory name_, 
        string memory symbol_) 
        AdventureERC721C(maxSimultaneousQuests_, name_, symbol_) {
        if(!IERC165(wrappedCollectionAddress_).supportsInterface(type(IERC721).interfaceId)) {
            revert AdventureERC721CW__InvalidERC721Collection();
        }

        wrappedCollection = IERC721(wrappedCollectionAddress_);
    }

    /// @notice Allows the contract owner to update the staker constraints.
    ///
    /// @dev    Throws when caller is not the contract owner.
    ///
    /// Postconditions:
    /// ---------------
    /// The staker constraints have been updated.
    /// A `StakerConstraintsSet` event has been emitted.
    function setStakerConstraints(StakerConstraints stakerConstraints_) public onlyOwner {
        stakerConstraints = stakerConstraints_;
        emit StakerConstraintsSet(stakerConstraints_);
    }

    /// @notice Allows holders of the wrapped ERC721 token to stake into this enhanced ERC721 token.
    /// The out of the box enhancements are AdventureERC721 staking features and the ERC721-C standard, but developers 
    /// can further extend the functionality of this contract with additional powered up features.
    ///
    /// Throws when staker constraints is `CallerIsTxOrigin` and the caller is not the tx.origin.
    /// Throws when staker constraints is `EOA` and the caller has not verified their signature in the transfer
    /// validator contract.
    /// Throws when caller does not own the token id on the wrapped collection.
    /// Throws when inheriting contract reverts in the _onStake function (for example, in a pay to stake scenario).
    /// Throws when _mint function reverts (for example, when additional mint validation logic reverts).
    /// Throws when transferFrom function reverts (e.g. if this contract does not have approval to transfer token).
    /// 
    /// Postconditions:
    /// ---------------
    /// The staker's token is now owned by this contract.
    /// The staker has received a wrapper token on this contract with the same token id.
    /// A `Staked` event has been emitted.
    function stake(uint256 tokenId) public virtual payable override {
        StakerConstraints stakerConstraints_ = stakerConstraints;

        if (stakerConstraints_ == StakerConstraints.CallerIsTxOrigin) {
            if(_msgSender() != tx.origin) {
                revert AdventureERC721CW__SmartContractsNotPermittedToStake();
            }
        } else if (stakerConstraints_ == StakerConstraints.EOA) {
            ICreatorTokenTransferValidator transferValidator_ = getTransferValidator();
            if (address(transferValidator_) != address(0)) {
                if (!transferValidator_.isVerifiedEOA(_msgSender())) {
                    revert AdventureERC721CW__CallerSignatureNotVerifiedInEOARegistry();
                }
            }
        }

        address tokenOwner = wrappedCollection.ownerOf(tokenId);
        if(tokenOwner != _msgSender()) {
            revert AdventureERC721CW__CallerNotOwnerOfWrappedToken();
        }
        
        _onStake(tokenId, msg.value);
        _mint(tokenOwner, tokenId);
        emit Staked(tokenId, tokenOwner);
        wrappedCollection.transferFrom(tokenOwner, address(this), tokenId);
    }

    /// @notice Allows holders of this wrapper ERC721 token to unstake and receive the original wrapped token.
    /// @dev    In certain scenarios the user may have to exit all quests before unstaking.
    /// 
    /// Throws when caller does not own the token id of this wrapper collection.
    /// Throws when inheriting contract reverts in the _onUnstake function (for example, in a pay to unstake scenario).
    /// Throws when _burn function reverts (for example, when additional burn validation logic reverts).
    /// Throws when transferFrom function reverts (should not be the case, unless wrapped token has additional transfer validation logic).
    ///
    /// Postconditions:
    /// ---------------
    /// The wrapper token has been burned.
    /// The wrapped token with the same token id has been transferred to the address that owned the wrapper token.
    /// An `Unstaked` event has been emitted.
    function unstake(uint256 tokenId) public virtual payable override {
        address tokenOwner = ownerOf(tokenId);
        if(tokenOwner != _msgSender()) {
            revert AdventureERC721CW__CallerNotOwnerOfWrappingToken();
        }

        _onUnstake(tokenId, msg.value);
        _burn(tokenId);
        emit Unstaked(tokenId, tokenOwner);
        wrappedCollection.transferFrom(address(this), tokenOwner, tokenId);
    }

    /// @notice Returns true if the specified token id is available to be unstaked, false otherwise.
    /// @dev This should be overridden in most cases by inheriting contracts to implement the proper constraints.
    /// In the base implementation, a token is available to be unstaked if the wrapped token is owned by this contract
    /// and the wrapper token exists.
    function canUnstake(uint256 tokenId) public virtual view override returns (bool) {
        return _exists(tokenId) && wrappedCollection.ownerOf(tokenId) == address(this);
    }

    /// @notice Returns the staker constraints that are currently in effect.
    function getStakerConstraints() public view override returns (StakerConstraints) {
        return stakerConstraints;
    }

    /// @notice Returns the address of the wrapped ERC721 contract.
    function getWrappedCollectionAddress() public view override returns (address) {
        return address(wrappedCollection);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorTokenWrapperERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Optional logic hook that fires during stake transaction.
    function _onStake(uint256 /*tokenId*/, uint256 value) internal virtual {
        if(value > 0) {
            revert AdventureERC721CW__DefaultImplementationOfStakeDoesNotAcceptPayment();
        }
    }

    /// @dev Optional logic hook that fires during unstake transaction.
    function _onUnstake(uint256 /*tokenId*/, uint256 value) internal virtual {
        if(value > 0) {
            revert AdventureERC721CW__DefaultImplementationOfUnstakeDoesNotAcceptPayment();
        }
    }
}
