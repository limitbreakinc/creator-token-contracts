const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const { shouldSupportInterfaces } = require('./utils/introspection/SupportsInterface.behavior.ethers');
const { shouldBehaveLikeWhitelistedTransferToken } = require('./WhitelistedTransfer.behavior');
const ether = require('@openzeppelin/test-helpers/src/ether');

function shouldBehaveLikeCreatorToken(testUnstakeLogic, testRentableLogic) {
  context('Creator Tokens', function() {
    beforeEach(async function() {
      [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
      creatorToken = this.creatorToken;
      unprotectedToken = this.unprotectedToken;
      transferWhitelist = this.transferWhitelist;
    });

    it('Wrapped Collection Address Is Set', async function() {
      expect(await creatorToken.getWrappedCollectionAddress()).to.equal(unprotectedToken.address);
    });

    context("With Minted Unprotected Tokens", function() {
        beforeEach(async function() {
          await unprotectedToken.mintTo(addrs[0].address, 1);
          await unprotectedToken.mintTo(addrs[0].address, 2);
          await unprotectedToken.mintTo(addrs[1].address, 3);
          await unprotectedToken.mintTo(addrs[2].address, 4);
        });
  
        it("Reverts when user calls stake on creator token without owning the wrapped, unprotected token", async function() {
          await expectRevert(creatorToken.connect(addrs[1]).stake(1), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(addrs[2]).stake(2), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(addrs[0]).stake(3), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(addrs[0]).stake(4), "CallerNotOwnerOfWrappedToken()");
        });
  
        it("Reverts when user calls stake on creator token without approving transfer of their unprotected token", async function() {
          await expectRevert(creatorToken.connect(addrs[0]).stake(1), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[0]).stake(2), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[1]).stake(3), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[2]).stake(4), "ERC721: caller is not token owner nor approved");
        });
  
        it("Reverts when approved operator (global) calls stake on creator token", async function() {
          await unprotectedToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
          await unprotectedToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
          await unprotectedToken.connect(addrs[2]).setApprovalForAll(operator.address, true);
          await expectRevert(creatorToken.connect(operator).stake(1), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(2), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(3), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(4), "CallerNotOwnerOfWrappedToken()");
        });
  
        it("Reverts when approved operator (by token id) calls stake on creator token", async function() {
          await unprotectedToken.connect(addrs[0]).approve(operator.address, 1);
          await unprotectedToken.connect(addrs[0]).approve(operator.address, 2);
          await unprotectedToken.connect(addrs[1]).approve(operator.address, 3);
          await unprotectedToken.connect(addrs[2]).approve(operator.address, 4);
          await expectRevert(creatorToken.connect(operator).stake(1), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(2), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(3), "CallerNotOwnerOfWrappedToken()");
          await expectRevert(creatorToken.connect(operator).stake(4), "CallerNotOwnerOfWrappedToken()");
        });
  
        it("Reverts when user calls unstake on creator token before it has been stakeed and minted", async function() {
          await expectRevert(creatorToken.connect(addrs[0]).unstake(1), "ERC721: invalid token ID");
          await expectRevert(creatorToken.connect(addrs[0]).unstake(2), "ERC721: invalid token ID");
          await expectRevert(creatorToken.connect(addrs[1]).unstake(3), "ERC721: invalid token ID");
          await expectRevert(creatorToken.connect(addrs[2]).unstake(4), "ERC721: invalid token ID");
        });
  
        it("Reverts when users call stake on creator token without approving the creator token as an operator", async function() {
          await expectRevert(creatorToken.connect(addrs[0]).stake(1), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[0]).stake(2), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[1]).stake(3), "ERC721: caller is not token owner nor approved");
          await expectRevert(creatorToken.connect(addrs[2]).stake(4), "ERC721: caller is not token owner nor approved");
        });

        it("Reverts when users accidentally include ETH during a call to stake", async function() {
          await unprotectedToken.connect(addrs[0]).setApprovalForAll(operator.address, true);
          await unprotectedToken.connect(addrs[1]).setApprovalForAll(operator.address, true);
          await unprotectedToken.connect(addrs[2]).setApprovalForAll(operator.address, true);
          await expectRevert(creatorToken.connect(addrs[0]).stake(1, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfStakeDoesNotAcceptPayment()");
          await expectRevert(creatorToken.connect(addrs[0]).stake(2, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfStakeDoesNotAcceptPayment()");
          await expectRevert(creatorToken.connect(addrs[1]).stake(3, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfStakeDoesNotAcceptPayment()");
          await expectRevert(creatorToken.connect(addrs[2]).stake(4, { value: ethers.utils.parseEther('1.0')}), "DefaultImplementationOfStakeDoesNotAcceptPayment()");
        });
  
        context("When creator Token is an approved operator", function() {
          beforeEach(async function() {
            await unprotectedToken.connect(addrs[0]).setApprovalForAll(creatorToken.address, true);
            await unprotectedToken.connect(addrs[1]).setApprovalForAll(creatorToken.address, true);
            await unprotectedToken.connect(addrs[2]).setApprovalForAll(creatorToken.address, true);
          });
  
          it("Allows users to call stake on creator token", async function() {
            await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 1);
            await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 2);
            await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[1], 3);
            await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[2], 4);
          });
  
          context("With Minted Creator Tokens", function() {
            beforeEach(async function() {
              await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 1);
              await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 2);
              await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[1], 3);
              await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[2], 4);
  
              this.whitelistedTransferToken = creatorToken;
            });

            if(testUnstakeLogic) {
              testUnstakeLogic();
            }

            if(testRentableLogic) {
              testRentableLogic();
            }
  
            shouldBehaveLikeWhitelistedTransferToken();
          });
        });

        context("When A Multi-Sig Owns Unprotected Tokens", function() {
          beforeEach(async function() {
            MultiSigMock = await ethers.getContractFactory("MultiSigMock");
            multiSigMock = await MultiSigMock.deploy();
            await multiSigMock.deployed();

            await unprotectedToken.mintTo(multiSigMock.address, 5);
            await multiSigMock.setApprovalForAll(unprotectedToken.address, creatorToken.address, true);
            await creatorToken.enableSmartContractStakers();
          });

          it("Smart Contract Stakers Are Enabled", async function() {
            expect(await creatorToken.getSmartContractStakersDisabled()).to.be.false;
          });

          it("Reverts if contract owner enables smart contract stakers again", async function() {
            await expectRevert(creatorToken.enableSmartContractStakers(), "SmartContractStakingAlreadyEnabled()");
          });

          it("Allows multi-sig to stake into creator token when smart contract stakers are enabled", async function() {
            await multiSigMock.execStake(creatorToken.address, 5);
            expect(await creatorToken.ownerOf(5)).to.equal(multiSigMock.address);
          });

          it("Emits DisabledSmartContractStakers event when contract owner disables smart contract staking", async function() {
            await expect(creatorToken.connect(owner).disableSmartContractStakers())
                .to.emit(creatorToken, 'DisabledSmartContractStakers');
          });

          context("When Smart Contract Stakers Are Disabled", function() {
            beforeEach(async function() {
              await creatorToken.disableSmartContractStakers();
            });

            it("Smart Contract Stakers Are Enabled", async function() {
              expect(await creatorToken.getSmartContractStakersDisabled()).to.be.true;
            });

            it("Reverts if contract owner disables smart contract stakers again", async function() {
              await expectRevert(creatorToken.disableSmartContractStakers(), "SmartContractStakingAlreadyDisabled()");
            });

            it("Reverts if multi-sig stakes into creator token when smart contract stakers are disabled", async function() {
              await expectRevert(multiSigMock.execStake(creatorToken.address, 5), "SmartContractsNotPermittedToStake()");
            });

            it("Allows smart contract stakers to be re-enabled", async function() {
              await creatorToken.enableSmartContractStakers();
              expect(await creatorToken.getSmartContractStakersDisabled()).to.be.false;
            });

            it("Emits EnabledSmartContractStakers event when smart contract staking is re-enabled", async function() {
              await expect(creatorToken.connect(owner).enableSmartContractStakers())
                .to.emit(creatorToken, 'EnabledSmartContractStakers');
            });

            context("When multi sig stakers are re-enabled", function() {
              beforeEach(async function() {
                await creatorToken.enableSmartContractStakers();
              });

              it("Allows multi-sig to stake into creator token when smart contract stakers are re-enabled", async function() {
                await multiSigMock.execStake(creatorToken.address, 5);
                expect(await creatorToken.ownerOf(5)).to.equal(multiSigMock.address);
              });
            });

            context("When An EOA Registry Is Set", function() {
              beforeEach(async function() {
                EOARegistry = await ethers.getContractFactory("EOARegistry");
                eoaRegistry = await EOARegistry.deploy();
                await eoaRegistry.deployed();

                await creatorToken.setEOARegistry(eoaRegistry.address);

                await unprotectedToken.connect(addrs[0]).setApprovalForAll(creatorToken.address, true);
                await unprotectedToken.connect(addrs[1]).setApprovalForAll(creatorToken.address, true);
                await unprotectedToken.connect(addrs[2]).setApprovalForAll(creatorToken.address, true);

                await eoaRegistry.connect(addrs[0]).verifySignature(await getSignedMessage(addrs[0], "EOA"));
                await eoaRegistry.connect(addrs[1]).verifySignature(await getSignedMessage(addrs[1], "EOA"));
              });

              async function getSignedMessage(signer, message) {
                return await signer.signMessage(message);
              }

              it("Allows EOAs to Stake, And Reverts If Smart Contract Stakes", async function() {               
                await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 1);
                await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 2);
                await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[1], 3);
                await expectRevert(multiSigMock.execStake(creatorToken.address, 5), `SignatureNotVerifiedInEOARegistry("${multiSigMock.address}", "${eoaRegistry.address}")`);
                
              });

              it("Reverts if an EOA stakes without proving they are an EOA first", async function() {
                await expectRevert(creatorToken.connect(addrs[2]).stake(4), `SignatureNotVerifiedInEOARegistry("${addrs[2].address}", "${eoaRegistry.address}")`);
              });

              context("When multi sig stakers are re-enabled", function() {
                beforeEach(async function() {
                  await creatorToken.enableSmartContractStakers();
                });
  
                it("Allows multi-sig to stake into creator token when smart contract stakers are re-enabled", async function() {
                  await multiSigMock.execStake(creatorToken.address, 5);
                  expect(await creatorToken.ownerOf(5)).to.equal(multiSigMock.address);
                  await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 1);
                  await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[0], 2);
                  await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[1], 3);
                  await verifySuccessfulStake(unprotectedToken, creatorToken, addrs[2], 4);
                });

                it("Allows eoa registry to be set back to zero address", async function() {
                  await creatorToken.connect(owner).setEOARegistry(ZERO_ADDRESS);
                  expect(await creatorToken.getEOARegistry()).to.equal(ZERO_ADDRESS);
                });

                it("Reverts if contract owner sets EOA registy to a contract that does not implement IEOARegistry interface", async function() {
                  await expectRevert(creatorToken.connect(owner).setEOARegistry(multiSigMock.address), "InvalidEOARegistryContract()");
                });

                it("Reverts if contract owner sets EOA registy to an EOA account", async function() {
                  await expectRevert(creatorToken.connect(owner).setEOARegistry(addrs[3].address), "InvalidEOARegistryContract()");
                });

                it("Reverts if unauthorized account sets EOA registy to an EOA account", async function() {
                  await creatorToken.connect(owner).setEOARegistry(ZERO_ADDRESS);
                  await expectRevert(creatorToken.connect(addrs[3]).setEOARegistry(eoaRegistry.address), "Ownable: caller is not the owner");
                });
              });

            });
          });
        });
      });
  });
}

async function verifySuccessfulStake(unprotectedToken, creatorToken, user, tokenId) {
    const priorUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const priorCreatorTokenBalance = await creatorToken.balanceOf(user.address);

    const tx = await creatorToken.connect(user).stake(tokenId);
    const receipt = await tx.wait();

    const updatedUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const updatedCreatorTokenBalance = await creatorToken.balanceOf(user.address);

    expect(updatedUnprotectedTokenBalance - priorUnprotectedTokenBalance).to.equal(-1);
    expect(updatedCreatorTokenBalance - priorCreatorTokenBalance).to.equal(1);

    expect(await unprotectedToken.ownerOf(tokenId)).to.equal(creatorToken.address);
    expect(await creatorToken.ownerOf(tokenId)).to.equal(user.address);

    const transferEvents = getAllEvents(receipt, "Transfer", [ "Approval", "Transfer", "Staked" ]);
    const flattenedTransferEvents = transferEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        from: x.log.args["from"], 
        to: x.log.args["to"],
        tokenId: x.log.args["tokenId"].toNumber()
      }
    });

    const stakedEvents = getAllEvents(receipt, "Staked", [ "Approval", "Transfer", "Staked" ]);
    const flattenedStakedEvents = stakedEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        tokenId: x.log.args["tokenId"].toNumber(),
        account: x.log.args["account"]
      }
    });

    expect(flattenedTransferEvents.filter(event => event.contractAddress == unprotectedToken.address && event.from == user.address && event.to == creatorToken.address && event.tokenId == tokenId).length).to.equal(1);
    expect(flattenedTransferEvents.filter(event => event.contractAddress == creatorToken.address && event.from == ZERO_ADDRESS && event.to == user.address && event.tokenId == tokenId).length).to.equal(1);

    expect(flattenedStakedEvents.filter(event => event.contractAddress == creatorToken.address && event.account == user.address && event.tokenId == tokenId).length).to.equal(1);
}

async function verifySuccessfulPaidUnstake(unprotectedToken, creatorToken, user, tokenId, payment) {
    const unstakePrice = await creatorToken.getUnstakePrice();

    const provider = unprotectedToken.provider;
    const priorUserEtherBalance = await provider.getBalance(user.address);

    const priorUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const priorCreatorTokenBalance = await creatorToken.balanceOf(user.address);

    const tx = await creatorToken.connect(user).unstake(tokenId, {value: payment});
    const receipt = await tx.wait();
    const totalGasUsedWei = receipt.effectiveGasPrice.mul(receipt.gasUsed);

    const updatedUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const updatedCreatorTokenBalance = await creatorToken.balanceOf(user.address);
    const updatedUserEtherBalance = await provider.getBalance(user.address);

    expect(updatedUnprotectedTokenBalance - priorUnprotectedTokenBalance).to.equal(1);
    expect(updatedCreatorTokenBalance - priorCreatorTokenBalance).to.equal(-1);
    const etherBalanceChange = priorUserEtherBalance.sub(updatedUserEtherBalance);
    const effectiveBalanceChangeAfterPayment = etherBalanceChange.sub(totalGasUsedWei);
    expect(effectiveBalanceChangeAfterPayment).to.equal(unstakePrice);

    expect(await unprotectedToken.ownerOf(tokenId)).to.equal(user.address);
    await expectRevert(creatorToken.ownerOf(tokenId), "ERC721: invalid token ID");

    const transferEvents = getAllEvents(receipt, "Transfer", [ "Approval", "Transfer", "Unstaked" ]);
    const flattenedTransferEvents = transferEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        from: x.log.args["from"], 
        to: x.log.args["to"],
        tokenId: x.log.args["tokenId"].toNumber()
      }
    });

    const unstakedEvents = getAllEvents(receipt, "Unstaked", [ "Approval", "Transfer", "Unstaked" ]);
    const flattenedUnstakedEvents = unstakedEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        tokenId: x.log.args["tokenId"].toNumber(),
        account: x.log.args["account"]
      }
    });

    expect(flattenedTransferEvents.filter(event => event.contractAddress == unprotectedToken.address && event.from == creatorToken.address && event.to == user.address && event.tokenId == tokenId).length).to.equal(1);
    expect(flattenedTransferEvents.filter(event => event.contractAddress == creatorToken.address && event.from == user.address && event.to == ZERO_ADDRESS && event.tokenId == tokenId).length).to.equal(1);

    expect(flattenedUnstakedEvents.filter(event => event.contractAddress == creatorToken.address && event.account == user.address && event.tokenId == tokenId).length).to.equal(1);
}

async function verifySuccessfulTimeLockedUnstake(unprotectedToken, creatorToken, user, tokenId) {
    const priorUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const priorCreatorTokenBalance = await creatorToken.balanceOf(user.address);

    const tx = await creatorToken.connect(user).unstake(tokenId);
    const receipt = await tx.wait();

    const updatedUnprotectedTokenBalance = await unprotectedToken.balanceOf(user.address);
    const updatedCreatorTokenBalance = await creatorToken.balanceOf(user.address);

    expect(updatedUnprotectedTokenBalance - priorUnprotectedTokenBalance).to.equal(1);
    expect(updatedCreatorTokenBalance - priorCreatorTokenBalance).to.equal(-1);

    expect(await unprotectedToken.ownerOf(tokenId)).to.equal(user.address);
    await expectRevert(creatorToken.ownerOf(tokenId), "ERC721: invalid token ID");

    const transferEvents = getAllEvents(receipt, "Transfer", [ "Approval", "Transfer", "Unstaked" ]);
    const flattenedTransferEvents = transferEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        from: x.log.args["from"], 
        to: x.log.args["to"],
        tokenId: x.log.args["tokenId"].toNumber()
      }
    });

    const unstakedEvents = getAllEvents(receipt, "Unstaked", [ "Approval", "Transfer", "Unstaked" ]);
    const flattenedUnstakedEvents = unstakedEvents.map(x => {
      return { 
        contractAddress: x.contractAddress,
        tokenId: x.log.args["tokenId"].toNumber(),
        account: x.log.args["account"]
      }
    });

    expect(flattenedTransferEvents.filter(event => event.contractAddress == unprotectedToken.address && event.from == creatorToken.address && event.to == user.address && event.tokenId == tokenId).length).to.equal(1);
    expect(flattenedTransferEvents.filter(event => event.contractAddress == creatorToken.address && event.from == user.address && event.to == ZERO_ADDRESS && event.tokenId == tokenId).length).to.equal(1);

    expect(flattenedUnstakedEvents.filter(event => event.contractAddress == creatorToken.address && event.account == user.address && event.tokenId == tokenId).length).to.equal(1);
}

function getAllEvents(receipt, eventName, allExpectedEventNames) {
    const possibleEventSignatures = new Map();
    possibleEventSignatures.set("Transfer", "event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)");
    possibleEventSignatures.set("Approval", "event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)");
    possibleEventSignatures.set("Staked", "event Staked(uint256 indexed tokenId, address indexed account)");
    possibleEventSignatures.set("Unstaked", "event Unstaked(uint256 indexed tokenId, address indexed account)");

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
    shouldBehaveLikeCreatorToken,
    verifySuccessfulStake,
    verifySuccessfulPaidUnstake,
    verifySuccessfulTimeLockedUnstake
};