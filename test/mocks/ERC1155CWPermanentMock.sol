// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc1155c/presets/ERC1155CWPermanent.sol";

contract ERC1155CWPermanentMock is ERC1155CWPermanent {
    
    constructor(address wrappedCollectionAddress_) ERC1155CW(wrappedCollectionAddress_, "") {}

    function mint(address /*to*/, uint256 tokenId, uint256 amount) external {
        stake(tokenId, amount);
    }
}