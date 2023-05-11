// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/erc1155c/ERC1155C.sol";

contract ERC1155CMock is OwnableBasic, ERC1155C {
    
    constructor() ERC1155OpenZeppelin("") {}

    function mint(address to, uint256 tokenId, uint256 amount) external {
        _mint(to, tokenId, amount, "");
    }
}