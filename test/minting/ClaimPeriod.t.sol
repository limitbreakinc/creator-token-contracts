// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../mocks/minting/MerkleWhitelistMintMock.sol";
import "../mocks/ClonerMock.sol";
import "../interfaces/ITestCreatorMintableToken.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

abstract contract ClaimPeriodTest is Test {
    event ClaimPeriodClosing(uint256 claimPeriodClosingTimestamp);
    event ClaimPeriodOpened(uint256 claimPeriodClosingTimestamp);

    function _deployNewToken(address creator) internal virtual returns (ITestCreatorMintableToken) {
        vm.prank(creator);
        return ITestCreatorMintableToken(address(new MerkleWhitelistMintMock(100, 1, 90, 10)));
    }

    function testOpenClaimsInPast(uint256 claimClosingTimestamp, address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(claimClosingTimestamp < block.timestamp);

        ITestCreatorMintableToken token = _deployNewToken(creator);

        vm.prank(creator);
        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodMustBeClosedInTheFuture.selector);
        token.openClaims(claimClosingTimestamp);
    }

    function testOpenClaimsNotOwner(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);

        vm.expectRevert("Ownable: caller is not the owner");
        token.openClaims(block.timestamp + 1);
    }

    function testOpenClaimsAfterClosing(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        vm.startPrank(creator);
        vm.expectEmit(true, true, true, true);
        emit ClaimPeriodOpened(~uint256(0));
        token.openClaims(~uint256(0));

        assertEq(token.getClaimPeriodClosingTimestamp(), ~uint256(0));

        token.closeClaims(block.timestamp + 1);

        vm.warp(block.timestamp + 2);

        assertFalse(token.isClaimPeriodOpen());

        vm.expectEmit(true, true, true, true);
        emit ClaimPeriodOpened(~uint256(0));
        token.openClaims(~uint256(0));

        assert(token.isClaimPeriodOpen());
    }

    function testOpenClaimsAlreadyOpen(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.openClaims(~uint256(0));

        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimsMustBeClosedToReopen.selector);
        token.openClaims(~uint256(0));
    }

    function testCloseClaimsNotOpen(address creator) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));

        ITestCreatorMintableToken token = _deployNewToken(creator);
        vm.startPrank(creator);
        vm.expectRevert(ClaimPeriodBase.ClaimPeriodBase__ClaimPeriodIsNotOpen.selector);
        token.closeClaims(~uint256(0));
    }

    function testCloseClaimPeriod(address creator, uint256 claimPeriodClosingTimestamp_) public {
        vm.assume(creator != address(0));
        vm.assume(creator != address(this));
        vm.assume(claimPeriodClosingTimestamp_ > block.timestamp);

        ITestCreatorMintableToken token = _deployNewToken(creator);
        vm.startPrank(creator);
        token.openClaims(~uint256(0));

        vm.expectEmit(true, true, true, true);
        emit ClaimPeriodClosing(claimPeriodClosingTimestamp_);
        token.closeClaims(claimPeriodClosingTimestamp_);
    }
}
