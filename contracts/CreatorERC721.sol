// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/EOARegistryAccess.sol";
import "./whitelist/WhitelistedTransferERC721.sol";

error AmountMustBeGreaterThanZero();
error CallerNotOwnerOfWrappingToken();
error CallerNotOwnerOfWrappedToken();
error DefaultImplementationOfStakeDoesNotAcceptPayment();
error DefaultImplementationOfUnstakeDoesNotAcceptPayment();
error InvalidERC721Collection();
error InsufficientBalance();
error QuantityMustBeGreaterThanZero();
error RecipientMustBeNonZeroAddress();
error SignatureNotVerifiedInEOARegistry(address account, address eoaRegistry);
error SmartContractsNotPermittedToStake();
error SmartContractStakingAlreadyDisabled();
error SmartContractStakingAlreadyEnabled();
error WithdrawalUnsuccessful();

/**
 * @title CreatorERC721
 * @author Limit Break, Inc.
 * @notice Extends whitelist-transferrable ERC721 contracts and adds a staking feature used to wrap a basic ERC721 contract.
 * This token can only be transferred by a whitelisted caller.  Holders opt-in to this contract by staking, and it is possible
 * for holders to unstake at the developers' discretion.  The intent of this contract is to allow developers to upgrade existing
 * NFT collections and provide enhanced features.
 */
abstract contract CreatorERC721 is WhitelistedTransferERC721, EOARegistryAccess {

    /// @dev Points to an external ERC721 contract that will be wrapped via staking.
    IERC721 immutable private wrappedCollection;

    /// @dev A toggle that can allow or disallow smart contracts from staking.
    bool private smartContractStakersDisabled;

    /// @dev Emitted when the contract owner disables staking calls from smart contracts
    event DisabledSmartContractStakers();

    /// @dev Emitted when the contract owner enables staking calls from smart contracts
    event EnabledSmartContractStakers();

    /// @dev Emitted when a user stakes their token to receive a creator token.
    event Staked(uint256 indexed tokenId, address indexed account);

    /// @dev Emitted when a user unstakes their creator token to receive the original token.
    event Unstaked(uint256 indexed tokenId, address indexed account);

    /// @dev Constructor - specify the name, symbol, and wrapped contract addresses here
    constructor(address wrappedCollectionAddress_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        if(!IERC165(wrappedCollectionAddress_).supportsInterface(type(IERC721).interfaceId)) {
            revert InvalidERC721Collection();
        }

        wrappedCollection = IERC721(wrappedCollectionAddress_);
        smartContractStakersDisabled = true;
        emit DisabledSmartContractStakers();
    }

    /// @notice Allows contract owner to enable smart contracts as stakers.
    /// 
    /// Throws when smart contract stakers are enabled already.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// Smart contract stakers are enabled.
    /// An `EnabledSmartContractStakers` event has been emitted.
    function enableSmartContractStakers() external onlyOwner {
        if(!smartContractStakersDisabled) {
            revert SmartContractStakingAlreadyEnabled();
        }

        smartContractStakersDisabled = false;
        emit EnabledSmartContractStakers();
    }

    /// @notice Allows contract owner to disable smart contracts as stakers.
    /// 
    /// Throws when smart contract stakers are disabled already.
    /// Throws when caller is not the contract owner.
    /// 
    /// Postconditions:
    /// ---------------
    /// Smart contract stakers are disabled.
    /// A `DisabledSmartContractStakers` event has been emitted.
    function disableSmartContractStakers() external onlyOwner {
        if(smartContractStakersDisabled) {
            revert SmartContractStakingAlreadyDisabled();
        }

        smartContractStakersDisabled = true;
        emit DisabledSmartContractStakers();
    }

    /// @notice Allows contract owner to withdraw ETH that has been paid into the contract.
    /// This allows inadvertantly lost ETH to be recovered and it also allows the contract owner
    /// To collect funds that have been properly paid into the contract over time.
    ///
    /// Throws when caller is not the contract owner.
    /// Throws when the specified amount is zero.
    /// Throws when the specified recipient is zero address.
    /// Throws when the current balance in this contract is less than the specified amount.
    /// Throws when the ETH transfer is unsuccessful.
    ///
    /// Postconditions:
    /// ---------------
    /// The specified amount of ETH has been sent to the specified recipient.
    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner {
        if(amount == 0) {
            revert AmountMustBeGreaterThanZero();
        }

        if(recipient == address(0)) {
            revert RecipientMustBeNonZeroAddress();
        }

        if(address(this).balance < amount) {
            revert InsufficientBalance();
        }

        //slither-disable-next-line arbitrary-send        
        (bool success,) = recipient.call{value: amount}("");
        if(!success) {
            revert WithdrawalUnsuccessful();
        }
    }

    /// @notice Allows holders of the wrapped ERC721 token to stake into this enhanced ERC721 token.
    /// The out of the box enhancement is the capability enabled by the whitelisted transfer system.
    /// Developers can extend the functionality of this contract with additional powered up features.
    ///
    /// Throws when caller does not own the token id on the wrapped collection.
    /// Throws when caller is a smart contract, if smart contract stakers are disabled.
    /// Throws when inheriting contract reverts in the _onStake function (for example, in a pay to stake scenario).
    /// Throws when _mint function reverts (for example, when additional mint validation logic reverts).
    /// Throws when transferFrom function reverts (for example, if this contract does not have approval to transfer token).
    /// 
    /// Postconditions:
    /// ---------------
    /// The staker's token is now owned by this contract.
    /// The staker has received a wrapper token on this contract with the same token id.
    /// A `Staked` event has been emitted.
    function stake(uint256 tokenId) external payable {
        address tokenOwner = wrappedCollection.ownerOf(tokenId);
        if(tokenOwner != _msgSender()) {
            revert CallerNotOwnerOfWrappedToken();
        }
        
        if(smartContractStakersDisabled) {
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
        }
        
        _onStake(tokenId, msg.value);
        _mint(tokenOwner, tokenId);
        emit Staked(tokenId, tokenOwner);
        wrappedCollection.transferFrom(tokenOwner, address(this), tokenId);
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
    function unstake(uint256 tokenId) external payable {
        address tokenOwner = ownerOf(tokenId);
        if(tokenOwner != _msgSender()) {
            revert CallerNotOwnerOfWrappingToken();
        }

        _onUnstake(tokenId, msg.value);
        _burn(tokenId);
        emit Unstaked(tokenId, tokenOwner);
        wrappedCollection.transferFrom(address(this), tokenOwner, tokenId);
    }

    /// @notice Returns the address of the wrapped ERC721 contract.
    function getWrappedCollectionAddress() external view returns (address) {
        return address(wrappedCollection);
    }

    /// @notice Returns true if smart contract stakers are disabled, false otherwise.
    function getSmartContractStakersDisabled() external view returns (bool) {
        return smartContractStakersDisabled;
    }

    /// @notice Returns true if the specified token id is available to be unstaked, false otherwise.
    /// @dev This should be overridden in most cases by inheriting contracts to implement the proper constraints.
    /// In the base implementation, a token is available to be unstaked if the wrapped token is owned by this contract
    /// and the wrapper token exists.
    function canUnstake(uint256 tokenId) public virtual view returns (bool) {
        return _exists(tokenId) && wrappedCollection.ownerOf(tokenId) == address(this);
    }

    /// @dev Optional logic hook that fires during stake transaction.
    function _onStake(uint256 /*tokenId*/, uint256 value) internal virtual {
        if(value > 0) {
            revert DefaultImplementationOfStakeDoesNotAcceptPayment();
        }
    }

    /// @dev Optional logic hook that fires during unstake transaction.
    function _onUnstake(uint256 /*tokenId*/, uint256 value) internal virtual {
        if(value > 0) {
            revert DefaultImplementationOfUnstakeDoesNotAcceptPayment();
        }
    }
}
