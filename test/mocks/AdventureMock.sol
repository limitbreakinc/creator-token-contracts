// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../contracts/adventures/IAdventure.sol";
import "../../contracts/adventures/IAdventurousERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IAdventurousEarlyExits {
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId) external;
    function userExitAllQuests(uint256 tokenId, address adventure) external;
}

contract AdventureMock is Context, ERC165, IAdventure, IAdventurousEarlyExits {
    bool private doQuestsLockTokens;

    IAdventurousERC721 public immutable adventurousNFT;

    constructor(bool doQuestsLockTokens_, address adventurousNFTAddress) {
        doQuestsLockTokens = doQuestsLockTokens_;
        adventurousNFT = IAdventurousERC721(adventurousNFTAddress);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    function questsLockTokens() external view override returns (bool) {
        return doQuestsLockTokens;
    }

    function onQuestEntered(address, /*adventurer*/ uint256, /*tokenId*/ uint256 /*questId*/ ) external view override {
        require(_msgSender() == address(adventurousNFT), "Caller not adventurous token contract");
    }

    function onQuestExited(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256, /*questId*/
        uint256 /*questStartTimestamp*/
    ) external view override {
        require(_msgSender() == address(adventurousNFT), "Caller not adventurous token contract");
    }

    function enterQuest(uint256 tokenId, uint256 questId) external {
        adventurousNFT.enterQuest(tokenId, questId);
    }

    function exitQuest(uint256 tokenId, uint256 questId) external {
        adventurousNFT.exitQuest(tokenId, questId);
    }

    function adventureTransferFrom(address from, address to, uint256 tokenId) external {
        adventurousNFT.adventureTransferFrom(from, to, tokenId);
    }

    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external {
        adventurousNFT.adventureSafeTransferFrom(from, to, tokenId);
    }

    function adventureBurn(uint256 tokenId) external {
        adventurousNFT.adventureBurn(tokenId);
    }

    function userExitQuest(uint256 tokenId, address adventure, uint256 questId) external override {
        IAdventurousEarlyExits(address(adventurousNFT)).userExitQuest(tokenId, adventure, questId);
    }

    function userExitAllQuests(uint256 tokenId, address adventure) external override {
        IAdventurousEarlyExits(address(adventurousNFT)).userExitAllQuests(tokenId, adventure);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        IERC721(address(adventurousNFT)).transferFrom(from, to, tokenId);
    }
}
