// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title BasicRoyalties
 * @author Limit Break, Inc.
 * @dev An NFT mix-in contract implementing the most basic form of programmable royalties.
 */
abstract contract BasicRoyaltiesBase is ERC2981 {

    event DefaultRoyaltySet(address indexed receiver, uint96 feeNumerator);
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual override {
        super._setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual override {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
    }
}

abstract contract BasicRoyalties is BasicRoyaltiesBase {
    constructor(address receiver, uint96 feeNumerator) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}

abstract contract BasicRoyaltiesInitializable is BasicRoyaltiesBase {}