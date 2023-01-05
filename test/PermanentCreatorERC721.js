const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;

const { shouldBehaveLikeCreatorToken } = require('./CreatorToken.behavior');

describe("Permanent Creator ERC-721 Tokens", function () {

  beforeEach(async function () {
    [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
    
    ERC721Mock = await ethers.getContractFactory("ERC721Mock");
    this.unprotectedToken = await ERC721Mock.deploy("Unprotected Token", "UNPROTECTED");
    await this.unprotectedToken.deployed();

    TransferWhitelistRegistry = await ethers.getContractFactory("TransferWhitelistRegistry");
    this.transferWhitelist = await TransferWhitelistRegistry.deploy();
    await this.transferWhitelist.deployed();

    PermanentCreatorERC721Mock = await ethers.getContractFactory("PermanentCreatorERC721Mock");
  });

  context("Before Creation", function () {
    it('Reverts if wrapped collection address is set to an EOA during deployment', async function() {
        await expectRevert(PermanentCreatorERC721Mock.deploy(addrs[0].address, "Creator Protected Token", "CREATOR"), "function call to a non-contract account");
    });

    it('Reverts if wrapped collection address is not set to the address of an ERC-721 token during deployment', async function() {
        await expectRevert(PermanentCreatorERC721Mock.deploy(this.transferWhitelist.address, "Creator Protected Token", "CREATOR"), "InvalidERC721Collection()");
    });
  });

  context("After Creation", function() {
    beforeEach(async function() {      
      this.creatorToken = await PermanentCreatorERC721Mock.deploy(this.unprotectedToken.address, "Creator Protected Token", "CREATOR");
      await this.creatorToken.deployed();
    });

    function testUnstakeLogic() {
      context("Un-Stake Logic", function() {
        it("Reverts if a user tries to un-stake a creator token", async function() {
          await expectRevert(creatorToken.connect(addrs[0]).unstake(1), "UnstakeIsNotPermitted()");
          await expectRevert(creatorToken.connect(addrs[0]).unstake(2), "UnstakeIsNotPermitted()");
          await expectRevert(creatorToken.connect(addrs[1]).unstake(3), "UnstakeIsNotPermitted()");
          await expectRevert(creatorToken.connect(addrs[2]).unstake(4), "UnstakeIsNotPermitted()");
        });

        it("canUnstake always returns false", async function() {
          expect(await this.creatorToken.canUnstake(0)).to.be.false;
          expect(await this.creatorToken.canUnstake(1)).to.be.false;
          expect(await this.creatorToken.canUnstake(2)).to.be.false;
          expect(await this.creatorToken.canUnstake(3)).to.be.false;
          expect(await this.creatorToken.canUnstake(4)).to.be.false;
          expect(await this.creatorToken.canUnstake(5)).to.be.false;
        });
      });
    }

    shouldBehaveLikeCreatorToken(testUnstakeLogic);
  });
});