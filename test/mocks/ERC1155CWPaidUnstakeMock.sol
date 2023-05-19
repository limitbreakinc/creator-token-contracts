// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/access/OwnableBasic.sol";
import "../../contracts/erc1155c/presets/ERC1155CWPaidUnstake.sol";

contract ERC1155CWPaidUnstakeMock is OwnableBasic, ERC1155CWPaidUnstake {
    constructor(uint256 unstakeUnitPrice_, address wrappedCollectionAddress_)
        ERC1155CWPaidUnstake(unstakeUnitPrice_, wrappedCollectionAddress_, "")
    {}

    function mint(address, /*to*/ uint256 tokenId, uint256 amount) external {
        stake(tokenId, amount);
    }
}
