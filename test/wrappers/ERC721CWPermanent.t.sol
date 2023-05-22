// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../mocks/ERC721Mock.sol";
import "../mocks/ERC721CWPermanentMock.sol";
import "../CreatorTokenTransferValidatorERC721.t.sol";

contract ERC721CWPermanentTest is CreatorTokenTransferValidatorERC721Test {
    event Staked(uint256 indexed tokenId, address indexed account);
    event Unstaked(uint256 indexed tokenId, address indexed account);
    event StakerConstraintsSet(StakerConstraints stakerConstraints);

    ERC721Mock public wrappedTokenMock;
    ERC721CWPermanentMock public tokenMock;

    function setUp() public virtual override {
        super.setUp();

        wrappedTokenMock = new ERC721Mock();
        tokenMock = new ERC721CWPermanentMock(address(wrappedTokenMock));
        tokenMock.setToCustomValidatorAndSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken) {
        vm.startPrank(creator);
        address wrappedToken = address(new ERC721Mock());
        ITestCreatorToken token = ITestCreatorToken(address(new ERC721CWPermanentMock(wrappedToken)));
        vm.stopPrank();
        return token;
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId) internal virtual override {
        address wrappedTokenAddress = ERC721CWPermanentMock(tokenAddress).getWrappedCollectionAddress();
        vm.startPrank(to);
        ERC721Mock(wrappedTokenAddress).mint(to, tokenId);
        ERC721Mock(wrappedTokenAddress).setApprovalForAll(tokenAddress, true);
        ERC721CWPermanentMock(tokenAddress).mint(to, tokenId);
        vm.stopPrank();
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(ICreatorTokenWrapperERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC721Metadata).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
    }

    function testCanUnstakeReturnsFalseWhenTokensDoNotExist(uint256 tokenId) public {
        assertFalse(tokenMock.canUnstake(tokenId));
    }

    function testCanUnstakeReturnsFalseForStakedTokenIds(address to, uint256 tokenId) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        _mintToken(address(tokenMock), to, tokenId);
        assertFalse(tokenMock.canUnstake(tokenId));
    }

    function testWrappedCollectionHoldersCanStakeTokens(address to, uint256 tokenId) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        assertEq(tokenMock.ownerOf(tokenId), to);
        assertEq(wrappedTokenMock.ownerOf(tokenId), address(tokenMock));
    }

    function testRevertsWhenNativeFundsIncludedInStake(address to, uint256 tokenId, uint256 value) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        vm.assume(value > 0);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.deal(to, value);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__DefaultImplementationOfStakeDoesNotAcceptPayment.selector);
        tokenMock.stake{value: value}(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenUnauthorizedUserAttemptsToStake(address to, address unauthorizedUser, uint256 tokenId)
        public
    {
        vm.assume(to != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(to != unauthorizedUser);
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__CallerNotOwnerOfWrappedToken.selector);
        tokenMock.stake(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenApprovedOperatorAttemptsToStake(address to, address approvedOperator, uint256 tokenId)
        public
    {
        vm.assume(to != address(0));
        vm.assume(approvedOperator != address(0));
        vm.assume(to != approvedOperator);
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        wrappedTokenMock.setApprovalForAll(approvedOperator, true);
        vm.stopPrank();

        vm.startPrank(approvedOperator);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__CallerNotOwnerOfWrappedToken.selector);
        tokenMock.stake(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenUnauthorizedUserAttemptsToUnstake(address to, address unauthorizedUser, uint256 tokenId)
        public
    {
        vm.assume(to != address(0));
        vm.assume(unauthorizedUser != address(0));
        vm.assume(to != unauthorizedUser);
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__CallerNotOwnerOfWrappingToken.selector);
        tokenMock.unstake(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenApprovedOperatorAttemptsToUnstake(address to, address approvedOperator, uint256 tokenId)
        public
    {
        vm.assume(to != address(0));
        vm.assume(approvedOperator != address(0));
        vm.assume(to != approvedOperator);
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        wrappedTokenMock.setApprovalForAll(approvedOperator, true);
        tokenMock.setApprovalForAll(approvedOperator, true);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        vm.startPrank(approvedOperator);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__CallerNotOwnerOfWrappingToken.selector);
        tokenMock.unstake(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenUserAttemptsToUnstakeATokenThatHasNotBeenStaked(address to, uint256 tokenId) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.expectRevert("ERC721: invalid token ID");
        tokenMock.unstake(tokenId);
        vm.stopPrank();
    }

    function testWrappingCollectionHoldersCannotUnstakeTokens(address to, uint256 tokenId) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId);
        vm.expectRevert(ERC721CWPermanent.ERC721CWPermanent__UnstakeIsNotPermitted.selector);
        tokenMock.unstake(tokenId);
        vm.stopPrank();
    }

    function testRevertsWhenNativeFundsIncludedInUnstakeCall(address to, uint256 tokenId, uint256 value) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        vm.assume(value > 0);

        vm.deal(to, value);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId);
        vm.expectRevert(ERC721CWPermanent.ERC721CWPermanent__UnstakeIsNotPermitted.selector);
        tokenMock.unstake{value: value}(tokenId);
        vm.stopPrank();
    }

    function testSecondaryWrappingCollectionHoldersCannotUnstakeTokens(
        address to,
        address secondaryHolder,
        uint256 tokenId
    ) public {
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        vm.assume(secondaryHolder != address(0));
        vm.assume(secondaryHolder != address(tokenMock));
        vm.assume(to != secondaryHolder);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId);
        tokenMock.transferFrom(to, secondaryHolder, tokenId);
        vm.stopPrank();

        vm.startPrank(secondaryHolder);
        vm.expectRevert(ERC721CWPermanent.ERC721CWPermanent__UnstakeIsNotPermitted.selector);
        tokenMock.unstake(tokenId);
        vm.stopPrank();
    }

    function testCanSetStakerConstraints(uint8 constraintsUint8) public {
        vm.assume(constraintsUint8 <= 2);
        StakerConstraints constraints = StakerConstraints(constraintsUint8);

        vm.expectEmit(false, false, false, true);
        emit StakerConstraintsSet(constraints);
        tokenMock.setStakerConstraints(constraints);
        assertEq(uint8(tokenMock.getStakerConstraints()), uint8(constraints));
    }

    function testRevertsWhenUnauthorizedUserAttemptsToSetStakerConstraints(
        address unauthorizedUser,
        uint8 constraintsUint8
    ) public {
        vm.assume(unauthorizedUser != address(0));
        vm.assume(constraintsUint8 <= 2);
        StakerConstraints constraints = StakerConstraints(constraintsUint8);

        vm.prank(unauthorizedUser);
        vm.expectRevert("Ownable: caller is not the owner");
        tokenMock.setStakerConstraints(constraints);
    }

    function testEOACanStakeTokensWhenStakerConstraintsAreInEffect(address to, uint256 tokenId) public {
        _sanitizeAddress(to);
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        vm.assume(to.code.length == 0);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        tokenMock.setStakerConstraints(StakerConstraints.CallerIsTxOrigin);

        vm.startPrank(to, to);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        assertEq(tokenMock.ownerOf(tokenId), to);
        assertEq(wrappedTokenMock.ownerOf(tokenId), address(tokenMock));
    }

    function testEOACanStakeTokensWhenEOAStakerConstraintsAreInEffectButValidatorIsUnset(address to, uint256 tokenId)
        public
    {
        _sanitizeAddress(to);
        vm.assume(to != address(0));
        vm.assume(to != address(tokenMock));
        vm.assume(to.code.length == 0);

        tokenMock.setTransferValidator(address(0));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        tokenMock.setStakerConstraints(StakerConstraints.EOA);

        vm.startPrank(to, to);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        assertEq(tokenMock.ownerOf(tokenId), to);
        assertEq(wrappedTokenMock.ownerOf(tokenId), address(tokenMock));
    }

    function testVerifiedEOACanStakeTokensWhenEOAStakerConstraintsAreInEffect(uint160 toKey, uint256 tokenId) public {
        address to = _verifyEOA(toKey);
        _sanitizeAddress(to);
        vm.assume(to != address(0));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        tokenMock.setStakerConstraints(StakerConstraints.EOA);

        vm.startPrank(to);
        tokenMock.stake(tokenId);
        vm.stopPrank();

        assertEq(tokenMock.ownerOf(tokenId), to);
        assertEq(wrappedTokenMock.ownerOf(tokenId), address(tokenMock));
    }

    function testRevertsWhenCallerIsTxOriginConstraintIsInEffectIfCallerIsNotOrigin(
        address to,
        address origin,
        uint256 tokenId
    ) public {
        _sanitizeAddress(to);
        _sanitizeAddress(origin);
        vm.assume(to != address(0));
        vm.assume(origin != address(0));
        vm.assume(to != origin);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        tokenMock.setStakerConstraints(StakerConstraints.CallerIsTxOrigin);

        vm.prank(to, origin);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__SmartContractsNotPermittedToStake.selector);
        tokenMock.stake(tokenId);
    }

    function testRevertsWhenCallerIsEOAConstraintIsInEffectIfCallerHasNotVerifiedSignature(address to, uint256 tokenId)
        public
    {
        _sanitizeAddress(to);
        vm.assume(to != address(0));

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        tokenMock.setStakerConstraints(StakerConstraints.EOA);

        vm.prank(to);
        vm.expectRevert(ERC721WrapperBase.ERC721WrapperBase__CallerSignatureNotVerifiedInEOARegistry.selector);
        tokenMock.stake(tokenId);
    }

    function _sanitizeAddress(address addr) internal view virtual override {
        super._sanitizeAddress(addr);
        vm.assume(addr != address(tokenMock));
        vm.assume(addr != address(wrappedTokenMock));
    }
}
