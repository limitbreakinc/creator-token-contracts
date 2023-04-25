// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/ITransferValidator.sol";
import "../utils/TransferValidation.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title ERC721C
 * @author Limit Break, Inc.
 * @notice 
 */
abstract contract ERC1155C is Ownable, ERC1155, TransferValidation {
    
    error ERC1155C__InvalidTransferValidatorContract();

    ITransferValidator private transferValidator;

    event TransferValidatorUpdated(address oldValidator, address newValidator);

    constructor(address transferValidator_, string memory uri_) ERC1155(uri_) {
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
            revert ERC1155C__InvalidTransferValidatorContract();
        }

        emit TransferValidatorUpdated(address(transferValidator), transferValidator_);

        transferValidator = ITransferValidator(transferValidator_);
    }

    function getTransferValidator() public view returns (ITransferValidator) {
        return transferValidator;
    }

    /// @dev Ties the open-zeppelin _beforeTokenTransfer hook to more granular transfer validation logic
    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length;) {
            _validateBeforeTransfer(from, to, ids[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Ties the open-zeppelin _afterTokenTransfer hook to more granular transfer validation logic
    function _afterTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length;) {
            _validateAfterTransfer(from, to, ids[i]);

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
