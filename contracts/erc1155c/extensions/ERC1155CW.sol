// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ERC1155C.sol";
import "../../utils/WithdrawETH.sol";

/**
 * @title CreatorERC721
 * @author Limit Break, Inc.
 * @notice Extends whitelist-transferrable ERC721 contracts and adds a staking feature used to wrap a basic ERC721 contract.
 * This token can only be transferred by a whitelisted caller.  Holders opt-in to this contract by staking, and it is possible
 * for holders to unstake at the developers' discretion.  The intent of this contract is to allow developers to upgrade existing
 * NFT collections and provide enhanced features.
 *
 * @dev The base version of CreatorERC721 wrapper allows smart contract accounts and EOAs to stake to wrap tokens.
 * For developers that have a reason to restrict staking to EOA accounts only, see UncomposableCreatorERC721.
 */
abstract contract ERC1155CW is ERC1155C, WithdrawETH {

    error ERC1155CW__AmountMustBeGreaterThanZero();
    error ERC1155CW__InsufficientBalanceOfWrappedToken();
    error ERC1155CW__InsufficientBalanceOfWrappingToken();
    error ERC1155CW__DefaultImplementationOfStakeDoesNotAcceptPayment();
    error ERC1155CW__DefaultImplementationOfUnstakeDoesNotAcceptPayment();
    error ERC1155CW__InvalidERC1155Collection();

    /// @dev Points to an external ERC721 contract that will be wrapped via staking.
    IERC1155 immutable private wrappedCollection;

    /// @dev Emitted when a user stakes their token to receive a creator token.
    event Staked(uint256 indexed id, address indexed account, uint256 amount);

    /// @dev Emitted when a user unstakes their creator token to receive the original token.
    event Unstaked(uint256 indexed id, address indexed account, uint256 amount);

    /// @dev Constructor - specify the name, symbol, and wrapped contract addresses here
    constructor(
        address wrappedCollectionAddress_, 
        address transferValidator_, 
        string memory uri_) 
        ERC1155C(transferValidator_, uri_) {
        
        if(!IERC165(wrappedCollectionAddress_).supportsInterface(type(IERC1155).interfaceId)) {
            revert ERC1155CW__InvalidERC1155Collection();
        }

        wrappedCollection = IERC1155(wrappedCollectionAddress_);
    }

    /// @notice Allows holders of the wrapped ERC721 token to stake into this enhanced ERC721 token.
    /// The out of the box enhancement is the capability enabled by the whitelisted transfer system.
    /// Developers can extend the functionality of this contract with additional powered up features.
    ///
    /// Throws when caller does not own the token id on the wrapped collection.
    /// Throws when inheriting contract reverts in the _onStake function (for example, in a pay to stake scenario).
    /// Throws when _mint function reverts (for example, when additional mint validation logic reverts).
    /// Throws when transferFrom function reverts (for example, if this contract does not have approval to transfer token).
    /// 
    /// Postconditions:
    /// ---------------
    /// The staker's token is now owned by this contract.
    /// The staker has received a wrapper token on this contract with the same token id.
    /// A `Staked` event has been emitted.
    function stake(uint256 id, uint256 amount) public virtual payable {
        if (amount == 0) {
            revert ERC1155CW__AmountMustBeGreaterThanZero();
        }

        uint256 tokenBalance = wrappedCollection.balanceOf(_msgSender(), id);
        if (tokenBalance < amount) {
            revert ERC1155CW__InsufficientBalanceOfWrappedToken();
        }
        
        _onStake(id, amount, msg.value);
        _mint(_msgSender(), id, amount, "");
        emit Staked(id, _msgSender(), amount);
        wrappedCollection.safeTransferFrom(_msgSender(), address(this), id, amount, "");
    }

    /// @notice Allows holders of this wrapper ERC721 token to unstake and receive the original wrapped token.
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
    function unstake(uint256 id, uint256 amount) public virtual payable {
        if (amount == 0) {
            revert ERC1155CW__AmountMustBeGreaterThanZero();
        }

        uint256 tokenBalance = balanceOf(_msgSender(), id);
        if (tokenBalance < amount) {
            revert ERC1155CW__InsufficientBalanceOfWrappingToken();
        }

        _onUnstake(id, amount, msg.value);
        _burn(_msgSender(), id, amount);
        emit Unstaked(id, _msgSender(), amount);
        wrappedCollection.safeTransferFrom(address(this), _msgSender(), id, amount, "");
    }

    /// @notice Returns the address of the wrapped ERC721 contract.
    function getWrappedCollectionAddress() public view returns (address) {
        return address(wrappedCollection);
    }

    /// @notice Returns true if the specified token id is available to be unstaked, false otherwise.
    /// @dev This should be overridden in most cases by inheriting contracts to implement the proper constraints.
    /// In the base implementation, a token is available to be unstaked if the wrapped token is owned by this contract
    /// and the wrapper token exists.
    function canUnstake(uint256 id, uint256 amount) public virtual view returns (bool) {
        return wrappedCollection.balanceOf(address(this), id) >= amount;
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
