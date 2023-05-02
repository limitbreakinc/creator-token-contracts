// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "./mocks/ERC1155Mock.sol";
import "./mocks/ERC1155CWPaidUnstakeMock.sol";
import "./CreatorTokenTransferValidatorERC1155.t.sol";

contract ERC1155CWPaidUnstakeTest is CreatorTokenTransferValidatorERC1155Test {

    ERC1155Mock public wrappedTokenMock;
    ERC1155CWPaidUnstakeMock public tokenMock;

    function setUp() public virtual override {
        super.setUp();
        
        wrappedTokenMock = new ERC1155Mock();
        tokenMock = new ERC1155CWPaidUnstakeMock(1 ether, address(wrappedTokenMock));
        tokenMock.setToCustomSecurityPolicy(address(validator), TransferSecurityLevels.One, 1, 0);
    }

    function _deployNewToken(address creator) internal virtual override returns (ITestCreatorToken1155) {
        vm.startPrank(creator);
        address wrappedToken = address(new ERC1155Mock());
        ITestCreatorToken1155 token = ITestCreatorToken1155(address(new ERC1155CWPaidUnstakeMock(1 ether, wrappedToken)));
        vm.stopPrank();
        return token;
    }

    function _mintToken(address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual override {
        address wrappedTokenAddress = ERC1155CWPaidUnstakeMock(tokenAddress).getWrappedCollectionAddress();
        vm.startPrank(to);
        ERC1155Mock(wrappedTokenAddress).mint(to, tokenId, amount);
        ERC1155Mock(wrappedTokenAddress).setApprovalForAll(tokenAddress, true);
        ERC1155CWPaidUnstakeMock(tokenAddress).mint(to, tokenId, amount);
        vm.stopPrank();
    }

    function testSupportedTokenInterfaces() public {
        assertEq(tokenMock.supportsInterface(type(ICreatorToken).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(ICreatorTokenWrapperERC1155).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155MetadataURI).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC1155Receiver).interfaceId), true);
        assertEq(tokenMock.supportsInterface(type(IERC165).interfaceId), true);
    }

    function testCanUnstakeReturnsFalseWhenTokensDoNotExist(uint256 tokenId, uint256 amount) public {
        vm.assume(amount > 0);
        assertFalse(tokenMock.canUnstake(tokenId, amount));
    }

    function testCanUnstakeReturnsTrueForStakedTokens(address to, uint256 tokenId, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 0);
        _mintToken(address(tokenMock), to, tokenId, amount);
        assertTrue(tokenMock.canUnstake(tokenId, amount));
    }

    function testCanUnstakeReturnsTrueWhenBalanceOfWrapperTokenIsSufficient(address to, uint256 tokenId, uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > 0);
        vm.assume(amount >= amountToUnstake);
        _mintToken(address(tokenMock), to, tokenId, amount);
        assertTrue(tokenMock.canUnstake(tokenId, amountToUnstake));
    }

    function testCanUnstakeReturnsFalseWhenBalanceOfWrapperTokenIsInsufficient(address to, uint256 tokenId, uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > amount);
        _mintToken(address(tokenMock), to, tokenId, amount);
        assertFalse(tokenMock.canUnstake(tokenId, amountToUnstake));
    }

    function testWrappedCollectionHoldersCanStakeTokensGiveSufficientWrappedTokenBalance(address to, uint256 tokenId, uint256 amount, uint256 amountToStake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amountToStake);
        vm.stopPrank();

        assertEq(tokenMock.balanceOf(to, tokenId), amountToStake);
        assertEq(wrappedTokenMock.balanceOf(to, tokenId), amount - amountToStake);
        assertEq(wrappedTokenMock.balanceOf(address(tokenMock), tokenId), amountToStake);
    }

    function testRevertsWhenNativeFundsIncludedInStake(address to, uint256 tokenId, uint256 amount, uint256 amountToStake, uint256 value) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);
        vm.assume(value > 0);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.deal(to, value);
        vm.expectRevert(ERC1155CW.ERC1155CW__DefaultImplementationOfStakeDoesNotAcceptPayment.selector);
        tokenMock.stake{value: value}(tokenId, amountToStake);
        vm.stopPrank();
    }

    function testRevertsWhenUnauthorizedUserAttemptsToStake(address to, address unauthorizedUser, uint256 tokenId, uint256 amount, uint256 amountToStake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(to != unauthorizedUser);
        vm.assume(unauthorizedUser != address(0));
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        vm.expectRevert(ERC1155CW.ERC1155CW__InsufficientBalanceOfWrappedToken.selector);
        tokenMock.stake(tokenId, amountToStake);
        vm.stopPrank();
    }

    function testRevertsWhenApprovedOperatorAttemptsToStake(address to, address approvedOperator, uint256 tokenId, uint256 amount, uint256 amountToStake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(to != approvedOperator);
        vm.assume(approvedOperator != address(0));
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        wrappedTokenMock.setApprovalForAll(approvedOperator, true);
        vm.stopPrank();

        vm.startPrank(approvedOperator);
        vm.expectRevert(ERC1155CW.ERC1155CW__InsufficientBalanceOfWrappedToken.selector);
        tokenMock.stake(tokenId, amountToStake);
        vm.stopPrank();
    }

    function testRevertsWhenStakeCalledWithZeroAmount(address to, uint256 tokenId, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 0);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        vm.expectRevert(ERC1155CW.ERC1155CW__AmountMustBeGreaterThanZero.selector);
        tokenMock.stake(tokenId, 0);
        vm.stopPrank();
    }

    function testRevertsWhenUnauthorizedUserAttemptsToUnstake(address to, address unauthorizedUser, uint256 tokenId, uint256 amount, uint256 amountToStake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(to != unauthorizedUser);
        vm.assume(unauthorizedUser != address(0));
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amountToStake);
        vm.stopPrank();

        vm.startPrank(unauthorizedUser);
        vm.expectRevert(ERC1155CW.ERC1155CW__InsufficientBalanceOfWrappingToken.selector);
        tokenMock.unstake(tokenId, amountToStake);
        vm.stopPrank();
    }

    function testRevertsWhenApprovedOperatorAttemptsToUnstake(address to, address approvedOperator, uint256 tokenId, uint256 amount, uint256 amountToStake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(to != approvedOperator);
        vm.assume(approvedOperator != address(0));
        vm.assume(amount > 0);
        vm.assume(amountToStake > 0 && amountToStake <= amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        wrappedTokenMock.setApprovalForAll(approvedOperator, true);
        tokenMock.setApprovalForAll(approvedOperator, true);
        tokenMock.stake(tokenId, amountToStake);
        vm.stopPrank();

        vm.startPrank(approvedOperator);
        vm.expectRevert(ERC1155CW.ERC1155CW__InsufficientBalanceOfWrappingToken.selector);
        tokenMock.unstake(tokenId, amountToStake);
        vm.stopPrank();
    }

    function testRevertsWhenUserAttemptsToUnstakeATokenAmountThatHasNotBeenStaked(address to, uint256 tokenId,uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > amount);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        vm.expectRevert(ERC1155CW.ERC1155CW__InsufficientBalanceOfWrappingToken.selector);
        tokenMock.unstake(tokenId, amountToUnstake);
        vm.stopPrank();
    }

    function testWrappingCollectionHoldersCannotUnstakeIfUnstakePriceIsUnderpaid(address to, uint256 tokenId, uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > 0 && amountToUnstake <= amount);
        vm.assume(amountToUnstake < type(uint128).max);

        uint256 underpayment = amountToUnstake * tokenMock.getUnstakeUnitPrice() - 1;
        vm.deal(to, underpayment);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        vm.expectRevert(ERC1155CWPaidUnstake.ERC1155CWPaidUnstake__IncorrectUnstakePayment.selector);
        tokenMock.unstake{value: underpayment}(tokenId, amountToUnstake);
        vm.stopPrank();
    }

    function testWrappingCollectionHoldersCannotUnstakeIfUnstakePriceIsOverpaid(address to, uint256 tokenId, uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > 0 && amountToUnstake <= amount);
        vm.assume(amountToUnstake < type(uint128).max);

        uint256 overpayment = amountToUnstake * tokenMock.getUnstakeUnitPrice() + 1;
        vm.deal(to, overpayment);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        vm.expectRevert(ERC1155CWPaidUnstake.ERC1155CWPaidUnstake__IncorrectUnstakePayment.selector);
        tokenMock.unstake{value: overpayment}(tokenId, amountToUnstake);
        vm.stopPrank();
    }

    function testWrappingCollectionHoldersCanUnstakeIfExactUnstakePriceIsPaid(address to, uint256 tokenId, uint256 amount, uint256 amountToUnstake) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 1);
        vm.assume(amountToUnstake > 0 && amountToUnstake <= amount);
        vm.assume(amountToUnstake < type(uint128).max);

        uint256 unstakePayment = amountToUnstake * tokenMock.getUnstakeUnitPrice();
        vm.deal(to, unstakePayment);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        tokenMock.unstake{value: unstakePayment}(tokenId, amountToUnstake);
        vm.stopPrank();

        assertEq(tokenMock.balanceOf(to, tokenId), amount - amountToUnstake);
        assertEq(wrappedTokenMock.balanceOf(to, tokenId), amountToUnstake);
        assertEq(wrappedTokenMock.balanceOf(address(tokenMock), tokenId), amount - amountToUnstake);
    }

    function testRevertsWhenUnstakingZeroAmount(address to, uint256 tokenId, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(amount > 0);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        vm.expectRevert(ERC1155CW.ERC1155CW__AmountMustBeGreaterThanZero.selector);
        tokenMock.unstake{value: 0}(tokenId, 0);
        vm.stopPrank();
    }

    function testSecondaryWrappingCollectionHoldersCanUnstakeTokensByPayingStakePrice(address to, address secondaryHolder, uint256 tokenId, uint256 amount, uint256 amountToTransfer) public {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0);
        vm.assume(secondaryHolder != address(0));
        vm.assume(secondaryHolder.code.length == 0);
        vm.assume(to != secondaryHolder);
        vm.assume(amount > 1);
        vm.assume(amountToTransfer > 0 && amountToTransfer < amount);
        vm.assume(amount < type(uint128).max);

        vm.startPrank(to);
        wrappedTokenMock.mint(to, tokenId, amount);
        wrappedTokenMock.setApprovalForAll(address(tokenMock), true);
        tokenMock.stake(tokenId, amount);
        tokenMock.safeTransferFrom(to, secondaryHolder, tokenId, amountToTransfer, "");
        vm.stopPrank();

        uint256 unstakePayment1 = amountToTransfer * tokenMock.getUnstakeUnitPrice();
        vm.deal(secondaryHolder, unstakePayment1);

        vm.startPrank(secondaryHolder);
        tokenMock.unstake{value: unstakePayment1}(tokenId, amountToTransfer);
        vm.stopPrank();

        uint256 unstakePayment2 = (amount - amountToTransfer) * tokenMock.getUnstakeUnitPrice();
        vm.deal(to, unstakePayment2);

        vm.startPrank(to);
        tokenMock.unstake{value: unstakePayment2}(tokenId, amount - amountToTransfer);
        vm.stopPrank();

        assertEq(tokenMock.balanceOf(to, tokenId), 0);
        assertEq(tokenMock.balanceOf(secondaryHolder, tokenId), 0);
        assertEq(wrappedTokenMock.balanceOf(to, tokenId), amount - amountToTransfer);
        assertEq(wrappedTokenMock.balanceOf(secondaryHolder, tokenId), amountToTransfer);
        assertEq(wrappedTokenMock.balanceOf(address(tokenMock), tokenId), 0);
    }
}