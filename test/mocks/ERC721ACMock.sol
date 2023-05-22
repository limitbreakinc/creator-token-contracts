// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/erc721c/ERC721AC.sol";

contract ERC721ACMock is OwnableBasic, ERC721AC {
    constructor() ERC721AC("ERC-721C Mock", "MOCK") {}

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
