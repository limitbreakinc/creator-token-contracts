// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../contracts/erc721c/presets/ERC721CWTimeLockedUnstake.sol";

contract ERC721CWTimeLockedUnstakeMock is ERC721CWTimeLockedUnstake {
    constructor(uint256 timelockSeconds_, address wrappedCollectionAddress_) 
        ERC721CWTimeLockedUnstake(timelockSeconds_, wrappedCollectionAddress_, "ERC-721C Mock", "MOCK") {}

    function mint(address /*to*/, uint256 tokenId) external {
        stake(tokenId);
    }
}