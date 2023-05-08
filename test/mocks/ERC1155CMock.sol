// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc1155c/ERC1155C.sol";

contract ERC1155CMock is ERC1155C {
    
    constructor() ERC1155C("") {}

    function mint(address to, uint256 tokenId, uint256 amount) external {
        _mint(to, tokenId, amount, "");
    }
}