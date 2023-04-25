// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/ITransferValidator.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721C is IERC721 {
    event TransferValidatorUpdated(address oldValidator, address newValidator);

    function getTransferValidator() external view returns (ITransferValidator);
    function getSecurityPolicy() external view returns (CollectionSecurityPolicy memory);
    function getWhitelistedOperators() external view returns (address[] memory);
    function getPermittedContractReceivers() external view returns (address[] memory);
    function isOperatorWhitelisted(address operator) external view returns (bool);
    function isContractReceiverPermitted(address receiver) external view returns (bool);
    function isTransferAllowed(address caller, address from, address to) external view returns (bool);
}
