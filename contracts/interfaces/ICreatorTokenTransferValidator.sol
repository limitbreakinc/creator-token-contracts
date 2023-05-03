// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IEOARegistry.sol";
import "./ITransferSecurityRegistry.sol";
import "./ITransferValidator.sol";

interface ICreatorTokenTransferValidator is ITransferSecurityRegistry, ITransferValidator, IEOARegistry {}