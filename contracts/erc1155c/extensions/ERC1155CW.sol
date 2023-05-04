// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC1155C.sol";
import "../../interfaces/ICreatorTokenWrapperERC1155.sol";
import "../../utils/WithdrawETH.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title ERC1155CW
 * @author Limit Break, Inc.
 * @notice Extends ERC1155-C contracts and adds a staking feature used to wrap another ERC1155 contract.
 * The wrapper token gives the developer access to the same set of controls present in the ERC1155-C standard.  
 * Holders opt-in to this contract by staking, and it is possible for holders to unstake at the developers' discretion. 
 * The intent of this contract is to allow developers to upgrade existing NFT collections and provide enhanced features.
 *
 * @notice Creators also have discretion to set optional staker constraints should they wish to restrict staking to 
 *         EOA accounts only.
 */
abstract contract ERC1155CW is ERC1155C, ERC1155Holder, WithdrawETH, ReentrancyGuard, ICreatorTokenWrapperERC1155 {

    error ERC1155CW__AmountMustBeGreaterThanZero();
    error ERC1155CW__CallerSignatureNotVerifiedInEOARegistry();
    error ERC1155CW__InsufficientBalanceOfWrappedToken();
    error ERC1155CW__InsufficientBalanceOfWrappingToken();
    error ERC1155CW__DefaultImplementationOfStakeDoesNotAcceptPayment();
    error ERC1155CW__DefaultImplementationOfUnstakeDoesNotAcceptPayment();
    error ERC1155CW__InvalidERC1155Collection();
    error ERC1155CW__SmartContractsNotPermittedToStake();

    /// @dev Points to an external ERC1155 contract that will be wrapped via staking.
    IERC1155 immutable private wrappedCollection;

    /// @dev The staking constraints that will be used to determine if an address is eligible to stake tokens.
    StakerConstraints private stakerConstraints;

    /// @dev Constructor - specify the uri and wrapped contract addresses here
    constructor(address wrappedCollectionAddress_, string memory uri_) ERC1155C(uri_) {
        if(!IERC165(wrappedCollectionAddress_).supportsInterface(type(IERC1155).interfaceId)) {
            revert ERC1155CW__InvalidERC1155Collection();
        }

        wrappedCollection = IERC1155(wrappedCollectionAddress_);
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

    /// @notice Allows holders of the wrapped ERC1155 token to stake into this enhanced ERC1155 token.
    /// The out of the box enhancement is ERC1155-C standard, but developers can extend the functionality of this 
    /// contract with additional powered up features.
    ///
    /// Throws when staker constraints is `CallerIsTxOrigin` and the caller is not the tx.origin.
    /// Throws when staker constraints is `EOA` and the caller has not verified their signature in the transfer
    /// validator contract.
    /// Throws when amount is zero.
    /// Throws when caller does not have a balance greater than or equal to `amount` of the wrapped collection.
    /// Throws when inheriting contract reverts in the _onStake function (for example, in a pay to stake scenario).
    /// Throws when _mint function reverts (for example, when additional mint validation logic reverts).
    /// Throws when safeTransferFrom function reverts (e.g. if this contract does not have approval to transfer token).
    /// 
    /// Postconditions:
    /// ---------------
    /// The specified amount of the staker's token are now owned by this contract.
    /// The staker has received the equivalent amount of wrapper token on this contract with the same id.
    /// A `Staked` event has been emitted.
    function stake(uint256 id, uint256 amount) public virtual payable override nonReentrant {
        StakerConstraints stakerConstraints_ = stakerConstraints;

        if (stakerConstraints_ == StakerConstraints.CallerIsTxOrigin) {
            if(_msgSender() != tx.origin) {
                revert ERC1155CW__SmartContractsNotPermittedToStake();
            }
        } else if (stakerConstraints_ == StakerConstraints.EOA) {
            ICreatorTokenTransferValidator transferValidator_ = getTransferValidator();
            if (address(transferValidator_) != address(0)) {
                if (!transferValidator_.isVerifiedEOA(_msgSender())) {
                    revert ERC1155CW__CallerSignatureNotVerifiedInEOARegistry();
                }
            }
        }

        if (amount == 0) {
            revert ERC1155CW__AmountMustBeGreaterThanZero();
        }

        uint256 tokenBalance = wrappedCollection.balanceOf(_msgSender(), id);
        if (tokenBalance < amount) {
            revert ERC1155CW__InsufficientBalanceOfWrappedToken();
        }
        
        _onStake(id, amount, msg.value);
        emit Staked(id, _msgSender(), amount);
        _mint(_msgSender(), id, amount, "");
        wrappedCollection.safeTransferFrom(_msgSender(), address(this), id, amount, "");
    }

    /// @notice Allows holders of this wrapper ERC1155 token to unstake and receive the original wrapped tokens.
    /// 
    /// Throws when amount is zero.
    /// Throws when caller does not have a balance greater than or equal to amount of this wrapper collection.
    /// Throws when inheriting contract reverts in the _onUnstake function (for example, in a pay to unstake scenario).
    /// Throws when _burn function reverts (for example, when additional burn validation logic reverts).
    /// Throws when safeTransferFrom function reverts.
    ///
    /// Postconditions:
    /// ---------------
    /// The specified amount of wrapper token has been burned.
    /// The specified amount of wrapped token with the same id has been transferred to the caller.
    /// An `Unstaked` event has been emitted.
    function unstake(uint256 id, uint256 amount) public virtual payable override nonReentrant {
        if (amount == 0) {
            revert ERC1155CW__AmountMustBeGreaterThanZero();
        }

        uint256 tokenBalance = balanceOf(_msgSender(), id);
        if (tokenBalance < amount) {
            revert ERC1155CW__InsufficientBalanceOfWrappingToken();
        }

        _onUnstake(id, amount, msg.value);
        emit Unstaked(id, _msgSender(), amount);
        _burn(_msgSender(), id, amount);
        wrappedCollection.safeTransferFrom(address(this), _msgSender(), id, amount, "");
    }

    /// @notice Returns true if the specified token id and amount is available to be unstaked, false otherwise.
    /// @dev This should be overridden in most cases by inheriting contracts to implement the proper constraints.
    /// In the base implementation, tokens are available to be unstaked if the contract's balance of 
    /// the wrapped token is greater than or equal to amount.
    function canUnstake(uint256 id, uint256 amount) public virtual view override returns (bool) {
        return wrappedCollection.balanceOf(address(this), id) >= amount;
    }

    /// @notice Returns the staker constraints that are currently in effect.
    function getStakerConstraints() public view override returns (StakerConstraints) {
        return stakerConstraints;
    }

    /// @notice Returns the address of the wrapped ERC1155 contract.
    function getWrappedCollectionAddress() public view override returns (address) {
        return address(wrappedCollection);
    }

    /**
     * @notice Indicates whether the contract implements the specified interface.
     * @dev Overrides supportsInterface in ERC165.
     * @param interfaceId The interface id
     * @return true if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155C, ERC1155Receiver) returns (bool) {
        return interfaceId == type(ICreatorTokenWrapperERC1155).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Optional logic hook that fires during stake transaction.
    function _onStake(uint256 /*tokenId*/, uint256 /*amount*/, uint256 value) internal virtual {
        if(value > 0) {
            revert ERC1155CW__DefaultImplementationOfStakeDoesNotAcceptPayment();
        }
    }

    /// @dev Optional logic hook that fires during unstake transaction.
    function _onUnstake(uint256 /*tokenId*/, uint256 /*amount*/, uint256 value) internal virtual {
        if(value > 0) {
            revert ERC1155CW__DefaultImplementationOfUnstakeDoesNotAcceptPayment();
        }
    }
}
