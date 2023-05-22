// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ERC1155CMock.sol";
import "./mocks/ClonerMock.sol";
import "./CreatorTokenTransferValidatorERC1155.t.sol";

contract ERC1155CTest is CreatorTokenTransferValidatorERC1155Test {
    ERC1155CMock public tokenMock;

    function setUp() public virtual override {
        super.setUp();

        tokenMock = new ERC1155CMock();
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken1155) {
        vm.prank(creator);
        return ITestCreatorToken1155(address(new ERC1155CMock()));
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual override {
        ERC1155CMock(tokenAddress).mint(to, tokenId, amount);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155MetadataURI).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
    }
}

contract ERC1155CInitializableTest is CreatorTokenTransferValidatorERC1155Test {
    ClonerMock cloner;

    ERC1155CInitializableMock public referenceTokenMock;
    ERC1155CInitializableMock public tokenMock;

    function setUp() public virtual override {
        super.setUp();

        cloner = new ClonerMock();

        referenceTokenMock = new ERC1155CInitializableMock();

        bytes4[] memory initializationSelectors = new bytes4[](1);
        bytes[] memory initializationArguments = new bytes[](1);

        initializationSelectors[0] = referenceTokenMock.initializeERC1155.selector;
        initializationArguments[0] = abi.encode("testuri.com");

        tokenMock = ERC1155CInitializableMock(
            cloner.cloneContract(
                address(referenceTokenMock), address(this), initializationSelectors, initializationArguments
            )
        );
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken1155) {
        bytes4[] memory initializationSelectors = new bytes4[](1);
        bytes[] memory initializationArguments = new bytes[](1);

        initializationSelectors[0] = referenceTokenMock.initializeERC1155.selector;
        initializationArguments[0] = abi.encode("testuri.com");

        vm.prank(creator);
        return ITestCreatorToken1155(
            cloner.cloneContract(address(referenceTokenMock), creator, initializationSelectors, initializationArguments)
        );
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual override {
        ERC1155CInitializableMock(tokenAddress).mint(to, tokenId, amount);
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155MetadataURI).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
    }

    function testRevertsWhenInitializingOwnerAgain(address badOwner) public {
        vm.expectRevert(OwnableInitializable.InitializableOwnable__OwnerAlreadyInitialized.selector);
        tokenMock.initializeOwner(badOwner);
    }

    function testRevertsWhenInitializingERC1155Again(string memory uri) public {
        vm.expectRevert(
            ERC1155OpenZeppelinInitializable.ERC1155OpenZeppelinInitializable__AlreadyInitializedERC1155.selector
        );
        tokenMock.initializeERC1155(uri);
    }
}
