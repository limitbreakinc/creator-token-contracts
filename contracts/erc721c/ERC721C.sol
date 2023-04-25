// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ICreatorToken.sol";
import "../utils/ICreatorTokenTransferValidator.sol";
import "../utils/TransferValidation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC721C
 * @author Limit Break, Inc.
 * @notice 
 */
abstract contract ERC721C is Ownable, ERC721, TransferValidation, ICreatorToken {
    
    error ERC721C__InvalidTransferValidatorContract();

    ICreatorTokenTransferValidator private transferValidator;

    constructor(address transferValidator_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        setTransferValidator(transferValidator_);
    }

    function setTransferValidator(address transferValidator_) public onlyOwner {
        bool isValidTransferValidator = false;

        if(transferValidator_.code.length > 0) {
            try IERC165(transferValidator_).supportsInterface(type(ICreatorTokenTransferValidator).interfaceId) 
                returns (bool supportsInterface) {
                isValidTransferValidator = supportsInterface;
            } catch {}
        }

        if(transferValidator_ != address(0) && !isValidTransferValidator) {
            revert ERC721C__InvalidTransferValidatorContract();
        }

        emit TransferValidatorUpdated(address(transferValidator), transferValidator_);

        transferValidator = ICreatorTokenTransferValidator(transferValidator_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICreatorToken).interfaceId || super.supportsInterface(interfaceId);
    }

    function getTransferValidator() public view override returns (ITransferValidator) {
        return transferValidator;
    }

    function getSecurityPolicy() public view override returns (CollectionSecurityPolicy memory) {
        if (address(transferValidator) != address(0)) {
            return transferValidator.getCollectionSecurityPolicy(address(this));
        }

        return CollectionSecurityPolicy({
            transferSecurityLevel: TransferSecurityLevels.Zero,
            operatorWhitelistId: 0,
            permittedContractReceiversId: 0
        });
    }

    function getWhitelistedOperators() public view override returns (address[] memory) {
        if (address(transferValidator) != address(0)) {
            return transferValidator.getWhitelistedOperators(
                transferValidator.getCollectionSecurityPolicy(address(this)).operatorWhitelistId);
        }

        return new address[](0);
    }

    function getPermittedContractReceivers() public view override returns (address[] memory) {
        if (address(transferValidator) != address(0)) {
            return transferValidator.getPermittedContractReceivers(
                transferValidator.getCollectionSecurityPolicy(address(this)).permittedContractReceiversId);
        }

        return new address[](0);
    }

    function isOperatorWhitelisted(address operator) public view override returns (bool) {
        if (address(transferValidator) != address(0)) {
            return transferValidator.isOperatorWhitelisted(
                transferValidator.getCollectionSecurityPolicy(address(this)).operatorWhitelistId, operator);
        }

        return false;
    }

    function isContractReceiverPermitted(address receiver) public view override returns (bool) {
        if (address(transferValidator) != address(0)) {
            return transferValidator.isContractReceiverPermitted(
                transferValidator.getCollectionSecurityPolicy(address(this)).permittedContractReceiversId, receiver);
        }

        return false;
    }

    function isTransferAllowed(address caller, address from, address to) public view override returns (bool) {
        bool passesValidation = true;
        if (address(transferValidator) != address(0)) {
            try transferValidator.applyCollectionTransferPolicy(caller, from, to) {
                passesValidation = true;
            } catch {
                passesValidation = false;
            }
        }
        return passesValidation;
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateBeforeTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize) internal virtual override {
        for (uint256 i = 0; i < batchSize;) {
            _validateAfterTransfer(from, to, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    function _preValidateTransfer(
        address caller, 
        address from, 
        address to, 
        uint256 /*tokenId*/, 
        uint256 /*value*/) internal virtual override {
        if (address(transferValidator) != address(0)) {
            transferValidator.applyCollectionTransferPolicy(caller, from, to);
        }
    }
}
