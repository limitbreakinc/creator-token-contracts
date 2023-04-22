// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ITransferValidator.sol";
import "../utils/TransferValidation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC721C
 * @author Limit Break, Inc.
 * @notice 
 */
abstract contract ERC721C is Ownable, ERC721, TransferValidation {
    
    error ERC721C__InvalidTransferValidatorContract();

    ITransferValidator private transferValidator;

    event TransferValidatorUpdated(address oldValidator, address newValidator);

    constructor(address transferValidator_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        setTransferValidator(transferValidator_);
    }

    function setTransferValidator(address transferValidator_) public onlyOwner {
        bool isValidTransferValidator = false;

        if(transferValidator_.code.length > 0) {
            try IERC165(transferValidator_).supportsInterface(type(ITransferValidator).interfaceId) 
                returns (bool supportsInterface) {
                isValidTransferValidator = supportsInterface;
            } catch {}
        }

        if(transferValidator_ != address(0) && !isValidTransferValidator) {
            revert ERC721C__InvalidTransferValidatorContract();
        }

        emit TransferValidatorUpdated(address(transferValidator), transferValidator_);

        transferValidator = ITransferValidator(transferValidator_);
    }

    function getTransferValidator() public view returns (ITransferValidator) {
        return transferValidator;
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateBeforeTransfer(from, to, tokenId);
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _validateAfterTransfer(from, to, tokenId);
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
