// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 _decimals;

    constructor(uint8 decimals_) ERC20("ERC20Mock", "E20M") {
        _decimals = decimals_;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}