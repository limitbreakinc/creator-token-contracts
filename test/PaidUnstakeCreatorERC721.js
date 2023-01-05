const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;

const ONE_ETH = ethers.utils.parseEther('1');
const THREE_ETH = ethers.utils.parseEther('3');
const ONE_THOUSAND_ETH = ethers.utils.parseEther('1000');

const { shouldBehaveLikeCreatorToken, verifySuccessfulPaidUnstake } = require('./CreatorToken.behavior');

describe("Paid Unstake Creator ERC-721 Tokens", function () {

  beforeEach(async function () {
    [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
    
    ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    this.unprotectedToken = await ERC721Mock.deploy("Unprotected Token", "UNPROTECTED");
    await this.unprotectedToken.deployed();

    TransferWhitelistRegistry = await ethers.getContractFactory("TransferWhitelistRegistry");
    this.transferWhitelist = await TransferWhitelistRegistry.deploy();
    await this.transferWhitelist.deployed();

    PaidUnstakeCreatorERC721Mock = await ethers.getContractFactory("PaidUnstakeCreatorERC721Mock");
  });

  context("Before Creation", function () {
    it('Reverts if wrapped collection address is set to an EOA during deployment', async function() {
        await expectRevert(PaidUnstakeCreatorERC721Mock.deploy(ONE_ETH, addrs[0].address, "Creator Protected Token", "CREATOR"), "function call to a non-contract account");
    });

    it('Reverts if wrapped collection address is not set to the address of an ERC-721 token during deployment', async function() {
        await expectRevert(PaidUnstakeCreatorERC721Mock.deploy(ONE_ETH, this.transferWhitelist.address, "Creator Protected Token", "CREATOR"), "InvalidERC721Collection()");
    });
  });

  context("After Creation", function() {
    beforeEach(async function() {      
      this.creatorToken = await PaidUnstakeCreatorERC721Mock.deploy(ONE_ETH, this.unprotectedToken.address, "Creator Protected Token", "CREATOR");
      await this.creatorToken.deployed();
    });

    function testUnstakeLogic() {
      context("Un-stake Logic", function() {
        it("canUnstake always returns true for tokens that exist", async function() {
          expect(await this.creatorToken.canUnstake(0)).to.be.false;
          expect(await this.creatorToken.canUnstake(1)).to.be.true;
          expect(await this.creatorToken.canUnstake(2)).to.be.true;
          expect(await this.creatorToken.canUnstake(3)).to.be.true;
          expect(await this.creatorToken.canUnstake(4)).to.be.true;
          expect(await this.creatorToken.canUnstake(5)).to.be.false;
        });

        it("Reverts if a user tries to un-stake a creator token without paying the unstake price", async function() {
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(1), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(2), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(3), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(4), "IncorrectUnstakePayment()");
        });

        it("Reverts if non-owner attempts to un-stake a creator token", async function() {
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(1), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(2), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(3), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(3), "CallerNotOwnerOfWrappingToken()");
        });

        it("Reverts if approved non-owner attempts to un-stake a creator token", async function() {
          await this.creatorToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
          await this.creatorToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
          await this.creatorToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

          await expectRevert(this.creatorToken.connect(operator).unstake(1), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(2), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(3), "CallerNotOwnerOfWrappingToken()");
          await expectRevert(this.creatorToken.connect(operator).unstake(3), "CallerNotOwnerOfWrappingToken()");
        });

        it("Reverts if users un-stake a creator token and overpay the unstake price", async function() {
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(1, {value: THREE_ETH}), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[0]).unstake(2, {value: THREE_ETH}), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[1]).unstake(3, {value: THREE_ETH}), "IncorrectUnstakePayment()");
          await expectRevert(this.creatorToken.connect(addrs[2]).unstake(4, {value: THREE_ETH}), "IncorrectUnstakePayment()");
        });

        it("Allows users to un-stake a creator token if they pay the exact unstake price", async function() {
          await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 1, ONE_ETH);
          await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 2, ONE_ETH);
          await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[1], 3, ONE_ETH);
          await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[2], 4, ONE_ETH);
        });

        context("After unstaking payments", function() {
          beforeEach(async function() {
            await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 1, ONE_ETH);
            await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[0], 2, ONE_ETH);
            await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[1], 3, ONE_ETH);
            await verifySuccessfulPaidUnstake(this.unprotectedToken, this.creatorToken, addrs[2], 4, ONE_ETH);
          });

          it("canUnstake always returns false", async function() {
            expect(await this.creatorToken.canUnstake(0)).to.be.false;
            expect(await this.creatorToken.canUnstake(1)).to.be.false;
            expect(await this.creatorToken.canUnstake(2)).to.be.false;
            expect(await this.creatorToken.canUnstake(3)).to.be.false;
            expect(await this.creatorToken.canUnstake(4)).to.be.false;
            expect(await this.creatorToken.canUnstake(5)).to.be.false;
          });

          it("Reverts if payment is withdrawn to zero address", async function() {
            await expectRevert(this.creatorToken.connect(owner).withdrawETH(ZERO_ADDRESS, ONE_ETH), "RecipientMustBeNonZeroAddress()");
          });

          it("Reverts if zero amount is withdrawn", async function() {
            await expectRevert(this.creatorToken.connect(owner).withdrawETH(owner.address, 0), "AmountMustBeGreaterThanZero()");
          });

          it("Reverts if amount withdrawn exceeds balance", async function() {
            await expectRevert(this.creatorToken.connect(owner).withdrawETH(owner.address, ONE_THOUSAND_ETH), "InsufficientBalance()");
          });

          it("Reverts if withdrawal fails", async function() {
            RejectEtherMock = await ethers.getContractFactory("RejectEtherMock");
            const etherRejector = await RejectEtherMock.deploy();
            await etherRejector.deployed();
            await expectRevert(this.creatorToken.connect(owner).withdrawETH(etherRejector.address, ONE_ETH), "WithdrawalUnsuccessful()");
          });

          it("Reverts if unauthorized account attempts to withdraw ETH", async function() {
            await expectRevert(this.creatorToken.connect(addrs[0]).withdrawETH(addrs[0].address, ONE_ETH), "Ownable: caller is not the owner");
          });

          it("Allows contract owner to withdraw ETH in small amounts", async function() {
            const priorBalance = await this.creatorToken.provider.getBalance(addrs[3].address);
            await this.creatorToken.connect(owner).withdrawETH(addrs[3].address, ONE_ETH);
            await this.creatorToken.connect(owner).withdrawETH(addrs[3].address, ONE_ETH);
            await this.creatorToken.connect(owner).withdrawETH(addrs[3].address, ONE_ETH);
            await this.creatorToken.connect(owner).withdrawETH(addrs[3].address, ONE_ETH);
            const updatedBalance = await this.creatorToken.provider.getBalance(addrs[3].address);
            expect(updatedBalance.sub(priorBalance)).to.equal(ethers.utils.parseEther('4'));
          });

          it("Allows contract owner to withdraw all available ETH at once", async function() {
            const priorBalance = await this.creatorToken.provider.getBalance(addrs[3].address);
            await this.creatorToken.connect(owner).withdrawETH(addrs[3].address, ethers.utils.parseEther('4'));
            const updatedBalance = await this.creatorToken.provider.getBalance(addrs[3].address);
            expect(updatedBalance.sub(priorBalance)).to.equal(ethers.utils.parseEther('4'));
          });
        });
      });
    }

    shouldBehaveLikeCreatorToken(testUnstakeLogic);
  });
});