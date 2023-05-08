// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ERC721ACMock.sol";
import "./CreatorTokenTransferValidatorERC721.t.sol";

contract ERC721ACTest is CreatorTokenTransferValidatorERC721Test {

    ERC721ACMock public tokenMock;

    function setUp() public virtual override {
        super.setUp();
        
        tokenMock = new ERC721ACMock();
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.prank(creator);
        return ITestCreatorToken(address(new ERC721ACMock()));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        ERC721ACMock(tokenAddress).mint(to, tokenId);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
    }
}