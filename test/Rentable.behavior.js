const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;
const helpers = require("@nomicfoundation/hardhat-network-helpers");

const { shouldSupportInterfaces } = require('./utils/introspection/SupportsInterface.behavior.ethers');

function shouldBehaveLikeRentableToken() {
    context('Rentable Tokens', function() {
        beforeEach(async function() {
          [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
          rentableToken = this.rentableToken;
        });

        describe('interfaces', function() {
          beforeEach(async function () {
            this.token = rentableToken;
          });

          context(`ERC165`, function() {
            shouldSupportInterfaces([
              'ERC165',
            ]);
          });

          context(`ERC2981`, function() {
            shouldSupportInterfaces([
              "ERC2981"
            ]);
          });

          context(`ERC4907`, function() {
            shouldSupportInterfaces([
              "ERC4907"
            ]);
          });
        });

        describe('royalty setup', function() {
          it("reverts when setRoyaltyInfo is called with a royalty fee that exceeds the maximum fee", async function() {
            await expectRevert(rentableToken.connect(owner).setRoyaltyInfo(owner.address, 10000), "ExceedsMaxRoyaltyFee()");
            await expectRevert(rentableToken.connect(owner).setRoyaltyInfo(owner.address, 1001), "ExceedsMaxRoyaltyFee()");
          });
      
          it("reverts when setRoyaltyInfo is called with address(0) as the recipient", async function() {
            await expectRevert(rentableToken.connect(owner).setRoyaltyInfo(ZERO_ADDRESS, 1000), "ERC2981: invalid receiver");
          });
      
          it("allows royalty fees to be set to zero", async function() {      
            await rentableToken.connect(owner).setRoyaltyInfo(owner.address, 0);
            const royaltyInfo = await rentableToken.royaltyInfo(1, 1000000);
            const recipient = royaltyInfo[0];
            const royaltyAmount = royaltyInfo[1];      
            expect(recipient).to.equal(owner.address);
            expect(royaltyAmount).to.equal(0);
          });
      
          it("allows royalty fees to be set up to the max fee", async function() {      
            const maxFee = 1000;
            await rentableToken.connect(owner).setRoyaltyInfo(owner.address, maxFee);
            const royaltyInfo = await rentableToken.royaltyInfo(1, 1000000);
            const recipient = royaltyInfo[0];
            const royaltyAmount = royaltyInfo[1];
            expect(recipient).to.equal(owner.address);
            expect(royaltyAmount).to.equal(1000000 * maxFee / 10000);
          });
      
          it("emits RoyaltySet event when royalties are set", async function() {
            await expect(rentableToken.connect(owner).setRoyaltyInfo(owner.address, 1000))
                .to.emit(rentableToken, 'RoyaltySet')
                .withArgs(owner.address, 1000);
          });
        });

        describe("Rentable ERC-4907", function() {

          beforeEach(async function() {
            await rentableToken.connect(owner).setRoyaltyInfo(owner.address, 1000);
          });
          
          describe("setUser", function() {
            it("Reverts if the user that does not own the token attempts to set the user of a token", async function() {
              const latestTimestamp = await getLatestBlockTimestamp(rentableToken, true);
              const expirationTimestamp = latestTimestamp + 86400;
              await expectRevert(rentableToken.connect(operator).setUser(1, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(operator).setUser(2, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(operator).setUser(3, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(operator).setUser(4, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
            });

            it("Reverts if the user that owns the token attempts to set the user of a token", async function() {
              const latestTimestamp = await getLatestBlockTimestamp(rentableToken, true);
              const expirationTimestamp = latestTimestamp + 86400;
              await expectRevert(rentableToken.connect(addrs[0]).setUser(1, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(addrs[0]).setUser(2, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(addrs[1]).setUser(3, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
              await expectRevert(rentableToken.connect(addrs[2]).setUser(4, addrs[5].address, expirationTimestamp), "SetUserFunctionIsUnsupported()");
            });
          });

          context("Before tokens are rentable", function() {
            it("isRentable(tokenId) should return false", async function() {
              expect(await rentableToken.isRentable(1)).to.be.false;
              expect(await rentableToken.isRentable(2)).to.be.false;
              expect(await rentableToken.isRentable(3)).to.be.false;
              expect(await rentableToken.isRentable(4)).to.be.false;
            });

            it("rentalRatesPerMinute(tokenId) should be zero", async function() {
              expect(await rentableToken.rentalRatesPerMinute(1)).to.equal(0);
              expect(await rentableToken.rentalRatesPerMinute(2)).to.equal(0);
              expect(await rentableToken.rentalRatesPerMinute(3)).to.equal(0);
              expect(await rentableToken.rentalRatesPerMinute(4)).to.equal(0);
            });

            it("userOf(tokenId) should return zero address", async function() {
              expect(await rentableToken.userOf(1)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(2)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(3)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(4)).to.equal(ZERO_ADDRESS);
            });

            it("userExpires(tokenId) should return zero", async function() {
              expect(await rentableToken.userExpires(1)).to.equal(0);
              expect(await rentableToken.userExpires(2)).to.equal(0);
              expect(await rentableToken.userExpires(3)).to.equal(0);
              expect(await rentableToken.userExpires(4)).to.equal(0);
            });

            it("Reverts if a user attempts to rent an unrentable token", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).rent(1, 10), "TokenUnrentable()");
              await expectRevert(rentableToken.connect(addrs[5]).rent(2, 10), "TokenUnrentable()");
              await expectRevert(rentableToken.connect(addrs[5]).rent(3, 10), "TokenUnrentable()");
              await expectRevert(rentableToken.connect(addrs[5]).rent(4, 10), "TokenUnrentable()");
            });

            it("Reverts if account other than token owner tries to set the rental fee", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(1, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(2, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(3, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(4, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
            });

            it("Allows token owners to set a rental fee", async function() {
              await rentableToken.connect(addrs[0]).setRentalFee(1, ethers.utils.parseEther('0.00001'));
              expect(await rentableToken.isRentable(1)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(1)).to.equal(ethers.utils.parseEther('0.00001'));
              
              await rentableToken.connect(addrs[0]).setRentalFee(2, ethers.utils.parseEther('0.00002'));
              expect(await rentableToken.isRentable(2)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(2)).to.equal(ethers.utils.parseEther('0.00002'));

              await rentableToken.connect(addrs[1]).setRentalFee(3, ethers.utils.parseEther('0.00003'));
              expect(await rentableToken.isRentable(3)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(3)).to.equal(ethers.utils.parseEther('0.00003'));

              await rentableToken.connect(addrs[2]).setRentalFee(4, ethers.utils.parseEther('0.00004'));
              expect(await rentableToken.isRentable(4)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(4)).to.equal(ethers.utils.parseEther('0.00004'));
            });
          });

          context("After token rental fees are set", function() {
            beforeEach(async function() {
              await rentableToken.connect(addrs[0]).setRentalFee(1, ethers.utils.parseEther('0.00001'));
              await rentableToken.connect(addrs[0]).setRentalFee(2, ethers.utils.parseEther('0.00002'));
              await rentableToken.connect(addrs[1]).setRentalFee(3, ethers.utils.parseEther('0.00003'));
              await rentableToken.connect(addrs[2]).setRentalFee(4, ethers.utils.parseEther('0.00004'));
            });

            it("isRentable(tokenId) should return true", async function() {
              expect(await rentableToken.isRentable(1)).to.be.true;
              expect(await rentableToken.isRentable(2)).to.be.true;
              expect(await rentableToken.isRentable(3)).to.be.true;
              expect(await rentableToken.isRentable(4)).to.be.true;
            });

            it("rentalRatesPerMinute(tokenId) should be populated", async function() {
              expect(await rentableToken.rentalRatesPerMinute(1)).to.equal(ethers.utils.parseEther('0.00001'));
              expect(await rentableToken.rentalRatesPerMinute(2)).to.equal(ethers.utils.parseEther('0.00002'));
              expect(await rentableToken.rentalRatesPerMinute(3)).to.equal(ethers.utils.parseEther('0.00003'));
              expect(await rentableToken.rentalRatesPerMinute(4)).to.equal(ethers.utils.parseEther('0.00004'));
            });

            it("userOf(tokenId) should return zero address", async function() {
              expect(await rentableToken.userOf(1)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(2)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(3)).to.equal(ZERO_ADDRESS);
              expect(await rentableToken.userOf(4)).to.equal(ZERO_ADDRESS);
            });

            it("userExpires(tokenId) should return zero", async function() {
              expect(await rentableToken.userExpires(1)).to.equal(0);
              expect(await rentableToken.userExpires(2)).to.equal(0);
              expect(await rentableToken.userExpires(3)).to.equal(0);
              expect(await rentableToken.userExpires(4)).to.equal(0);
            });

            it("Reverts if account other than token owner tries to change the rental fee", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(1, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(2, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(3, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
              await expectRevert(rentableToken.connect(addrs[5]).setRentalFee(4, ethers.utils.parseEther('0.00001')), "CallerNotOwnerOfToken()");
            });

            it("Allows token owners to change the rental fee", async function() {
              await rentableToken.connect(addrs[0]).setRentalFee(1, ethers.utils.parseEther('0.00002'));
              expect(await rentableToken.isRentable(1)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(1)).to.equal(ethers.utils.parseEther('0.00002'));
              
              await rentableToken.connect(addrs[0]).setRentalFee(2, ethers.utils.parseEther('0.00004'));
              expect(await rentableToken.isRentable(2)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(2)).to.equal(ethers.utils.parseEther('0.00004'));

              await rentableToken.connect(addrs[1]).setRentalFee(3, ethers.utils.parseEther('0.00006'));
              expect(await rentableToken.isRentable(3)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(3)).to.equal(ethers.utils.parseEther('0.00006'));

              await rentableToken.connect(addrs[2]).setRentalFee(4, ethers.utils.parseEther('0.00008'));
              expect(await rentableToken.isRentable(4)).to.be.true;
              expect(await rentableToken.rentalRatesPerMinute(4)).to.equal(ethers.utils.parseEther('0.00008'));
            });

            it("Allows token owners to cancel rentability for tokens they own", async function() {
              await rentableToken.connect(addrs[0]).setRentalFee(1, ethers.utils.parseEther('0'));
              expect(await rentableToken.isRentable(1)).to.be.false;
              expect(await rentableToken.rentalRatesPerMinute(1)).to.equal(ethers.utils.parseEther('0'));
              
              await rentableToken.connect(addrs[0]).setRentalFee(2, ethers.utils.parseEther('0'));
              expect(await rentableToken.isRentable(2)).to.be.false;
              expect(await rentableToken.rentalRatesPerMinute(2)).to.equal(ethers.utils.parseEther('0'));

              await rentableToken.connect(addrs[1]).setRentalFee(3, ethers.utils.parseEther('0'));
              expect(await rentableToken.isRentable(3)).to.be.false;
              expect(await rentableToken.rentalRatesPerMinute(3)).to.equal(ethers.utils.parseEther('0'));

              await rentableToken.connect(addrs[2]).setRentalFee(4, ethers.utils.parseEther('0'));
              expect(await rentableToken.isRentable(4)).to.be.false;
              expect(await rentableToken.rentalRatesPerMinute(4)).to.equal(ethers.utils.parseEther('0'));
            });

            it("Revert if a user attempts to rent a token id for zero minutes", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).rent(1, 0, { value: ethers.utils.parseEther('10') }), "MinimumRentalPeriodIsOneMinute");
              await expectRevert(rentableToken.connect(addrs[5]).rent(2, 0, { value: ethers.utils.parseEther('10') }), "MinimumRentalPeriodIsOneMinute");
              await expectRevert(rentableToken.connect(addrs[5]).rent(3, 0, { value: ethers.utils.parseEther('10') }), "MinimumRentalPeriodIsOneMinute");
              await expectRevert(rentableToken.connect(addrs[5]).rent(4, 0, { value: ethers.utils.parseEther('10') }), "MinimumRentalPeriodIsOneMinute");
            });

            it("Revert if a user attempts to rent a token id and underpays", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).rent(1, 60, { value: ethers.utils.parseEther('0') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(2, 60, { value: ethers.utils.parseEther('0') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(3, 60, { value: ethers.utils.parseEther('0') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(4, 60, { value: ethers.utils.parseEther('0') }), "IncorrectRentalPayment");
            });

            it("Revert if a user attempts to rent a token id and overpays", async function() {
              await expectRevert(rentableToken.connect(addrs[5]).rent(1, 60, { value: ethers.utils.parseEther('10') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(2, 60, { value: ethers.utils.parseEther('10') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(3, 60, { value: ethers.utils.parseEther('10') }), "IncorrectRentalPayment");
              await expectRevert(rentableToken.connect(addrs[5]).rent(4, 60, { value: ethers.utils.parseEther('10') }), "IncorrectRentalPayment");
            });

            it("Allows users to rent tokens if they paid the exact rental price for the requested duration", async function() {
              await verifySuccessfulRental(rentableToken, addrs[5], 1, 50);
              await verifySuccessfulRental(rentableToken, addrs[6], 2, 1000);
              await verifySuccessfulRental(rentableToken, addrs[7], 3, 1);
              await verifySuccessfulRental(rentableToken, addrs[8], 4, 500);
            });

            it("Allows users to rent tokens even if royalty bips is set to zero", async function() {
              await rentableToken.connect(owner).setRoyaltyInfo(owner.address, 0);
              await verifySuccessfulRental(rentableToken, addrs[5], 1, 50);
              await verifySuccessfulRental(rentableToken, addrs[6], 2, 1000);
              await verifySuccessfulRental(rentableToken, addrs[7], 3, 1);
              await verifySuccessfulRental(rentableToken, addrs[8], 4, 500);
            });

            context("After tokens have been rented", function() {
              beforeEach(async function() {
                await verifySuccessfulRental(rentableToken, addrs[5], 1, 100);
                await verifySuccessfulRental(rentableToken, addrs[6], 2, 100);
                await verifySuccessfulRental(rentableToken, addrs[7], 3, 100);
                await verifySuccessfulRental(rentableToken, addrs[8], 4, 100);
              });

              it("Reverts if another user attempts to rent a token that is currently rented", async function() {
                await fastForward(99);
                await expectRevert(rentableToken.connect(addrs[9]).rent(1, 100, { value: ethers.utils.parseEther('.001') }), "AlreadyRented()");
                await expectRevert(rentableToken.connect(addrs[9]).rent(2, 100, { value: ethers.utils.parseEther('.002') }), "AlreadyRented()");
                await expectRevert(rentableToken.connect(addrs[9]).rent(3, 100, { value: ethers.utils.parseEther('.003') }), "AlreadyRented()");
                await expectRevert(rentableToken.connect(addrs[9]).rent(4, 100, { value: ethers.utils.parseEther('.004') }), "AlreadyRented()");
              });

              it("Properly expires users after their rental period is over", async function() {
                await fastForward(100);
                expect(await rentableToken.userOf(1)).to.equal(ZERO_ADDRESS);
                expect(await rentableToken.userOf(2)).to.equal(ZERO_ADDRESS);
                expect(await rentableToken.userOf(3)).to.equal(ZERO_ADDRESS);
                expect(await rentableToken.userOf(4)).to.equal(ZERO_ADDRESS);
              });

              it("Allows new users to rent tokens after previous rental expires", async function() {
                await fastForward(100);
                await verifySuccessfulRental(rentableToken, addrs[9], 1, 200);
                await verifySuccessfulRental(rentableToken, addrs[9], 2, 200);
                await verifySuccessfulRental(rentableToken, addrs[9], 3, 200);
                await verifySuccessfulRental(rentableToken, addrs[9], 4, 200);
              });
            });

            async function verifySuccessfulRental(token, renter, tokenId, durationMinutes) {
              
              const provider = token.provider;
              const rentalRaterPerMinute = await rentableToken.rentalRatesPerMinute(tokenId);
              const rentalFee = rentalRaterPerMinute.mul(durationMinutes);

              const royaltyInfo = await token.royaltyInfo(tokenId, rentalFee);
              const royaltyRecipient = royaltyInfo[0];
              const royaltyAmount = royaltyInfo[1];
              const priorRoyaltyReceiverEtherBalance = await provider.getBalance(royaltyRecipient);
              const priorTokenOwnerEtherBalance = await provider.getBalance(await token.ownerOf(tokenId));
              
              await token.connect(renter).rent(tokenId, durationMinutes, { value: rentalFee });

              const updatedRoyaltyReceiverEtherBalance = await provider.getBalance(royaltyRecipient);
              const updatedTokenOwnerEtherBalance = await provider.getBalance(await token.ownerOf(tokenId));

              const deltaRoyaltyReceiverEtherBalance = updatedRoyaltyReceiverEtherBalance.sub(priorRoyaltyReceiverEtherBalance);
              const deltaTokenOwnerEtherBalance = updatedTokenOwnerEtherBalance.sub(priorTokenOwnerEtherBalance);
              expect(deltaRoyaltyReceiverEtherBalance).to.equal(royaltyAmount);
              expect(deltaTokenOwnerEtherBalance).to.equal(rentalFee.sub(royaltyAmount));

              const minedBlockTimestamp = await getLatestBlockTimestamp(token);
              const expectedExpiration = minedBlockTimestamp + (durationMinutes * 60);

              expect(await token.userOf(tokenId)).to.equal(renter.address);
              expect(await token.userExpires(tokenId)).to.equal(expectedExpiration);
            }
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

module.exports = {
    shouldBehaveLikeRentableToken
};