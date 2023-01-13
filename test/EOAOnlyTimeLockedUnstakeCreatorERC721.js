const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const { shouldBehaveLikeCreatorToken, verifySuccessfulTimeLockedUnstake } = require('./EOAOnlyCreatorToken.behavior');

const ONE_DAY = 1440 * 1;

describe("EOA Only Time Locked Unstake Creator ERC-721 Tokens", function () {

  beforeEach(async function () {
    [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
    
    ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    this.unprotectedToken = await ERC721Mock.deploy("Unprotected Token", "UNPROTECTED");
    await this.unprotectedToken.deployed();

    TransferWhitelistRegistry = await ethers.getContractFactory("TransferWhitelistRegistry");
    this.transferWhitelist = await TransferWhitelistRegistry.deploy();
    await this.transferWhitelist.deployed();

    TimeLockedUnstakeCreatorERC721Mock = await ethers.getContractFactory("EOAOnlyTimeLockedUnstakeCreatorERC721Mock");
  });

  context("Before Creation", function () {
    it('Reverts if wrapped collection address is set to an EOA during deployment', async function() {
        await expectRevert(TimeLockedUnstakeCreatorERC721Mock.deploy(ONE_DAY, addrs[0].address, "Creator Protected Token", "CREATOR"), "function call to a non-contract account");
    });

    it('Reverts if wrapped collection address is not set to the address of an ERC-721 token during deployment', async function() {
        await expectRevert(TimeLockedUnstakeCreatorERC721Mock.deploy(ONE_DAY, this.transferWhitelist.address, "Creator Protected Token", "CREATOR"), "InvalidERC721Collection()");
    });
  });

  context("After Creation", function() {
    beforeEach(async function() {      
      this.creatorToken = await TimeLockedUnstakeCreatorERC721Mock.deploy(ONE_DAY, this.unprotectedToken.address, "Creator Protected Token", "CREATOR");
      await this.creatorToken.deployed();
    });

    function testUnstakeLogic() {
      context("Un-stake Logic", function() {
        it("canUnstake always returns false before the timelock expires", async function() {
          expect(await this.creatorToken.canUnstake(0)).to.be.false;
          expect(await this.creatorToken.canUnstake(1)).to.be.false;
          expect(await this.creatorToken.canUnstake(2)).to.be.false;
          expect(await this.creatorToken.canUnstake(3)).to.be.false;
          expect(await this.creatorToken.canUnstake(4)).to.be.false;
          expect(await this.creatorToken.canUnstake(5)).to.be.false;
        });

        it("canUnstake always returns true after the timelock expires", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          expect(await this.creatorToken.canUnstake(0)).to.be.false;
          expect(await this.creatorToken.canUnstake(1)).to.be.true;
          expect(await this.creatorToken.canUnstake(2)).to.be.true;
          expect(await this.creatorToken.canUnstake(3)).to.be.true;
          expect(await this.creatorToken.canUnstake(4)).to.be.true;
          expect(await this.creatorToken.canUnstake(5)).to.be.false;
        });

        it("getStakedTimestamp returns non-zero value", async function() {
          expect(await this.creatorToken.getStakedTimestamp(1)).to.be.greaterThan(0);
          expect(await this.creatorToken.getStakedTimestamp(2)).to.be.greaterThan(0);
          expect(await this.creatorToken.getStakedTimestamp(3)).to.be.greaterThan(0);
          expect(await this.creatorToken.getStakedTimestamp(4)).to.be.greaterThan(0);
        });

        it("getStakedTimestamp returns zero value after tokens are unstaked", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 1);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 2);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[1], 3);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[2], 4);

          expect(await this.creatorToken.getStakedTimestamp(1)).to.equal(0);
          expect(await this.creatorToken.getStakedTimestamp(2)).to.equal(0);
          expect(await this.creatorToken.getStakedTimestamp(3)).to.equal(0);
          expect(await this.creatorToken.getStakedTimestamp(4)).to.equal(0);
        });

        it("Reverts if a user tries to un-stake a creator token before the timelock expires", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60) - 1;
          await fastForward(timelockMinutes);

          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(1), "TimelockHasNotExpired()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(2), "TimelockHasNotExpired()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(3), "TimelockHasNotExpired()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(4), "TimelockHasNotExpired()");
        });

        it("Reverts when users accidentally include ETH during a call to unstake after timelock expires", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(1, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfUnstakeDoesNotAcceptPayment()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(2, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfUnstakeDoesNotAcceptPayment()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(3, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfUnstakeDoesNotAcceptPayment()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(4, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfUnstakeDoesNotAcceptPayment()");
        });

        it("Allows users to un-stake a creator token if the timelock has expired", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 1);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 2);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[1], 3);
          await verifySuccessfulTimeLockedUnstake(this.unprotectedToken, this.creatorToken, addrs[2], 4);
        });

        it("Reverts if non-owner attempts to un-stake a creator token", async function() {
          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(1), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(2), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(3), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(3), "CallerNotOwnerOfWrappingToken()");
        });

        it("Reverts if approved non-owner attempts to un-stake a creator token", async function() {
          await this.creatorToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
          await this.creatorToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
          await this.creatorToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

          const timelockSeconds = await this.creatorToken.getTimelockSeconds();
          const timelockMinutes = Math.ceil(timelockSeconds / 60);
          await fastForward(timelockMinutes);

          await expectRevert(this.creatorToken.connect(operator).unstake(1), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(2), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(3), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(3), "CallerNotOwnerOfWrappingToken()");
        });
      });
    }

    shouldBehaveLikeCreatorToken(testUnstakeLogic);
  });
});

async function fastForward(minutes) {
  await helpers.mine(minutes + 1, { interval: 60 });
}