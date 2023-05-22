// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "contracts/interfaces/ICreatorToken.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITestCreatorToken is IERC721, ICreatorToken {
    function mint(address, uint256) external;
    function setTransferValidator(address transferValidator_) external;
    function setToDefaultSecurityPolicy() external;

    function setToCustomValidatorAndSecurityPolicy(
        address validator,
        TransferSecurityLevels level,
        uint120 operatorWhitelistId,
        uint120 permittedContractReceiversAllowlistId
    ) external;
}
