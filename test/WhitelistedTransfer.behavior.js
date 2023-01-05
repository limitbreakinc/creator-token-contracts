const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const { shouldSupportInterfaces } = require('./utils/introspection/SupportsInterface.behavior.ethers');

function shouldBehaveLikeWhitelistedTransferToken() {
  describe("Transfer Whitelist For Tokens", function() {
    async function verifySuccessfulTransfer(token, operator, fromUser, toUser, tokenId) {
        const priorFromUserTokenBalance = await token.balanceOf(fromUser.address);
        const priorToUserTokenBalance = await token.balanceOf(toUser.address);

        const tx = await token.connect(operator).transferFrom(fromUser.address, toUser.address, tokenId);
        const receipt = await tx.wait();

        const updatedFromUserTokenBalance = await token.balanceOf(fromUser.address);
        const updatedToUserTokenBalance = await token.balanceOf(toUser.address);

        expect(updatedFromUserTokenBalance - priorFromUserTokenBalance).to.equal(-1);
        expect(updatedToUserTokenBalance - priorToUserTokenBalance).to.equal(1);

        expect(await token.ownerOf(tokenId)).to.equal(toUser.address);

        const transferEvents = getAllEvents(receipt, "Transfer", [ "Approval", "Transfer" ]);
        const flattenedTransferEvents = transferEvents.map(x => {
          return { 
            contractAddress: x.contractAddress,
            from: x.log.args["from"], 
            to: x.log.args["to"],
            tokenId: x.log.args["tokenId"].toNumber()
          }
        });

        expect(flattenedTransferEvents.filter(event => event.contractAddress == token.address && event.from == fromUser.address && event.to == toUser.address && event.tokenId == tokenId).length).to.equal(1);
    }

    beforeEach(async function() {
      [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
      whitelistedTransferToken = this.whitelistedTransferToken;
    });

    context("When the transfer whitelist has not been set", function() {

      it("Reverts if transfer whitelist is set to an EOA", async function() {
        await expectRevert(whitelistedTransferToken.setWhitelistRegistry(addrs[0].address), "InvalidTransferWhitelistContract()");
      });

      it("Reverts if transfer whitelist is set to an address that does not implement ERC-165", async function() {
        MultiSigMock = await ethers.getContractFactory("MultiSigMock");
        multiSigMock = await MultiSigMock.deploy();
        await multiSigMock.deployed();
        
        await expectRevert(whitelistedTransferToken.setWhitelistRegistry(multiSigMock.address), "InvalidTransferWhitelistContract()");
      });

      it("Reverts if transfer whitelist is set to a contract that does not implement ITransferWhitelist interface", async function() {
        await expectRevert(whitelistedTransferToken.setWhitelistRegistry(this.unprotectedToken.address), "InvalidTransferWhitelistContract()");
      });

      it("Transfer whitelist is set to zero address", async function() {
        expect(await whitelistedTransferToken.getTransferWhitelist()).to.equal(ZERO_ADDRESS);
      });

      it("Tokens are freely transferrable between users", async function() {
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 1);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 2);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[1], addrs[1], addrs[3], 3);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[2], addrs[2], addrs[3], 4);
      });

      it("Tokens are freely sellable on via exchanges", async function() {
        await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
        await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
        await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 1);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 2);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[1], addrs[3], 3);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[2], addrs[3], 4);
      });
    });

    context("When the transfer whitelist has been set, but nothing has been whitelisted", function() {
      beforeEach(async function() {
        await whitelistedTransferToken.setWhitelistRegistry(this.transferWhitelist.address);
      });

      it("Reverts if a non-whitelisted exchange is unwhitelisted", async function() {
        await expectRevert(this.transferWhitelist.unwhitelistExchange(addrs[5].address), "ExchangeIsNotWhitelisted");
      });

      it("Transfer whitelist is set to specified whitelist registry address", async function() {
        expect(await whitelistedTransferToken.getTransferWhitelist()).to.equal(this.transferWhitelist.address);
      });

      it("Tokens are freely transferrable between users", async function() {
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 1);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 2);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[1], addrs[1], addrs[3], 3);
        await verifySuccessfulTransfer(whitelistedTransferToken, addrs[2], addrs[2], addrs[3], 4);
      });

      it("Tokens are freely sellable on via exchanges", async function() {
        await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
        await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
        await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 1);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 2);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[1], addrs[3], 3);
        await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[2], addrs[3], 4);
      });

      context("With whitelisted exchanges", function() {
        beforeEach(async function() {
          whitelistedExchange1 = addrs[5];
          whitelistedExchange2 = addrs[6];
          unwhitelistedExchange = operator;

          expect(await this.transferWhitelist.isWhitelistedExchange(whitelistedExchange1.address)).to.be.false;
          await this.transferWhitelist.whitelistExchange(whitelistedExchange1.address);
          expect(await this.transferWhitelist.getWhitelistedExchangeCount()).to.equal(1);
          expect(await this.transferWhitelist.isWhitelistedExchange(whitelistedExchange1.address)).to.be.true;

          expect(await this.transferWhitelist.isWhitelistedExchange(whitelistedExchange2.address)).to.be.false;
          await this.transferWhitelist.whitelistExchange(whitelistedExchange2.address);
          expect(await this.transferWhitelist.getWhitelistedExchangeCount()).to.equal(2);
          expect(await this.transferWhitelist.isWhitelistedExchange(whitelistedExchange2.address)).to.be.true;

          await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
          await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
          await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

          await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(whitelistedExchange1.address, true);
          await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(whitelistedExchange1.address, true);
          await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(whitelistedExchange1.address, true);

          await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(whitelistedExchange2.address, true);
          await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(whitelistedExchange2.address, true);
          await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(whitelistedExchange2.address, true);
        });

        it("Reverts if user attempts to sell via un-approved exchange", async function() {
          await expectRevert(whitelistedTransferToken.connect(unwhitelistedExchange).transferFrom(addrs[0].address, addrs[3].address, 1), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(unwhitelistedExchange).transferFrom(addrs[0].address, addrs[3].address, 2), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(unwhitelistedExchange).transferFrom(addrs[1].address, addrs[3].address, 3), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(unwhitelistedExchange).transferFrom(addrs[2].address, addrs[3].address, 4), "CallerIsNotWhitelisted(");
        });

        it("Reverts if user attempts transfer their token directly to another user without an exchange", async function() {
          await expectRevert(whitelistedTransferToken.connect(addrs[0]).transferFrom(addrs[0].address, addrs[3].address, 1), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(addrs[0]).transferFrom(addrs[0].address, addrs[3].address, 2), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(addrs[1]).transferFrom(addrs[1].address, addrs[3].address, 3), "CallerIsNotWhitelisted(");
          await expectRevert(whitelistedTransferToken.connect(addrs[2]).transferFrom(addrs[2].address, addrs[3].address, 4), "CallerIsNotWhitelisted(");
        });

        it("Tokens are freely sellable via whitelisted exchanges (whitelisted exchange 1)", async function() {
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange1, addrs[0], addrs[3], 1);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange1, addrs[0], addrs[3], 2);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange1, addrs[1], addrs[3], 3);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange1, addrs[2], addrs[3], 4);
        });

        it("Tokens are freely sellable via whitelisted exchanges (whitelisted exchange 2)", async function() {
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange2, addrs[0], addrs[3], 1);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange2, addrs[0], addrs[3], 2);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange2, addrs[1], addrs[3], 3);
          await verifySuccessfulTransfer(whitelistedTransferToken, whitelistedExchange2, addrs[2], addrs[3], 4);
        });

        it("Reverts if a whitelisted exchange is whitelisted again", async function() {
          await expectRevert(this.transferWhitelist.whitelistExchange(whitelistedExchange1.address), "ExchangeIsWhitelisted()");
          await expectRevert(this.transferWhitelist.whitelistExchange(whitelistedExchange2.address), "ExchangeIsWhitelisted()");
          expect(await this.transferWhitelist.getWhitelistedExchangeCount()).to.equal(2);
        });

        context("When exchanges are removed from the whitelist", function() {
          beforeEach(async function() {
            await this.transferWhitelist.unwhitelistExchange(whitelistedExchange1.address);
            expect(await this.transferWhitelist.getWhitelistedExchangeCount()).to.equal(1);
            await this.transferWhitelist.unwhitelistExchange(whitelistedExchange2.address);
            expect(await this.transferWhitelist.getWhitelistedExchangeCount()).to.equal(0);
          });

          it("Tokens are freely transferrable between users", async function() {
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 1);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 2);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[1], addrs[1], addrs[3], 3);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[2], addrs[2], addrs[3], 4);
          });

          it("Tokens are freely sellable on via exchanges", async function() {
            await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
            await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
            await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 1);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 2);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[1], addrs[3], 3);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[2], addrs[3], 4);
          });
        });

        context("When the whitelist registry is set back to ZERO_ADDRESS", function() {
          beforeEach(async function() {
            await this.whitelistedTransferToken.setWhitelistRegistry(ZERO_ADDRESS);
          });

          it("Tokens are freely transferrable between users", async function() {
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 1);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[0], addrs[0], addrs[3], 2);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[1], addrs[1], addrs[3], 3);
            await verifySuccessfulTransfer(whitelistedTransferToken, addrs[2], addrs[2], addrs[3], 4);
          });

          it("Tokens are freely sellable on via exchanges", async function() {
            await whitelistedTransferToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
            await whitelistedTransferToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
            await whitelistedTransferToken.connect(addrs[2]).setApprovalForAll(operator.address, true);

            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 1);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[0], addrs[3], 2);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[1], addrs[3], 3);
            await verifySuccessfulTransfer(whitelistedTransferToken, operator, addrs[2], addrs[3], 4);
          });
        });
      });
    });
  });
}

async function fastForward(minutes) {
  await helpers.mine(minutes + 1, { interval: 60 });
}

async function getLatestBlockTimestamp(contract, addOne) {
  const latestBlock = await contract.provider.getBlock("latest");
  return latestBlock.timestamp + (addOne ? 1 : 0);
}

function getAllEvents(receipt, eventName, allExpectedEventNames) {
  const possibleEventSignatures = new Map();
  possibleEventSignatures.set("Transfer", "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)");
  possibleEventSignatures.set("Approval", "event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)");

  const abi = [];
  for(let i = 0; i < allExpectedEventNames.length; i++) {
    abi.push(possibleEventSignatures.get(allExpectedEventNames[i]));
  }

  let iface = new ethers.utils.Interface(abi);
  let events = receipt.logs.map((log) => {
      return {
          contractAddress: log.address,
          log: iface.parseLog(log)
      };
  });

  const matchingEvents = [];
  for(let i = 0; i < events.length; i++) {
    if(events[i].log.name === eventName) {
      matchingEvents.push(events[i]);
    }
  }

  return matchingEvents;
}

module.exports = {
  shouldBehaveLikeWhitelistedTransferToken
};