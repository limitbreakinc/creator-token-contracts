// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/interfaces/ICreatorToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITestCreatorToken1155 is IERC1155, ICreatorToken {
    function mint(address, uint256, uint256) external;
    function setTransferValidator(address transferValidator_) external;
    function setToDefaultSecurityPolicy() external;
    
    function setToCustomSecurityPolicy(
        address validator, 
        TransferSecurityLevels level, 
        uint120 operatorWhitelistId, 
        uint120 permittedContractReceiversAllowlistId) external;
}