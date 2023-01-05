const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { ZERO_ADDRESS } = constants;

describe("EOA Registry", function () {

  beforeEach(async function () {
    [owner, operator, user1, minter, ...addrs] = await ethers.getSigners();
    
    EOARegistry = await ethers.getContractFactory("EOARegistry");
    this.eoaRegistry = await EOARegistry.deploy();
    await this.eoaRegistry.deployed();
  });

  it('Reverts if user passes in a signature signed by a different EOA', async function() {
    await expectRevert(this.eoaRegistry.connect(addrs[0]).verifySignature(await getSignedMessage(addrs[1], "EOA")), "CallerDidNotSignTheMessage()");
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.false;
  });

  it('Reverts if user passes in a signature signed by a different EOA (v, r, s)', async function() {
    const signature = await getSignedMessage(addrs[1], "EOA");
    const r = signature.slice(0, 66);
    const s = '0x' + signature.slice(66, 130);
    const v = '0x' + signature.slice(130, 132);
    await expectRevert(this.eoaRegistry.connect(addrs[0]).verifySignatureVRS(v, r, s), "CallerDidNotSignTheMessage()");
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.false;
  });

  it('Reverts if user passes in a signature after already being verified', async function() {
    await this.eoaRegistry.connect(addrs[0]).verifySignature(await getSignedMessage(addrs[0], "EOA"));
    await expectRevert(this.eoaRegistry.connect(addrs[0]).verifySignature(await getSignedMessage(addrs[0], "EOA")), "SignatureAlreadyVerified()");
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.true;
  });

  it('Reverts if user passes in a signature after already being verified (v, r, s)', async function() {
    const signature = await getSignedMessage(addrs[0], "EOA");
    const r = signature.slice(0, 66);
    const s = '0x' + signature.slice(66, 130);
    const v = '0x' + signature.slice(130, 132);
    await this.eoaRegistry.connect(addrs[0]).verifySignatureVRS(v, r, s);
    await expectRevert(this.eoaRegistry.connect(addrs[0]).verifySignatureVRS(v, r, s), "SignatureAlreadyVerified()");
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.true;
  });

  it('Allows a user to sign and prove they are an EOA', async function() {
    await this.eoaRegistry.connect(addrs[0]).verifySignature(await getSignedMessage(addrs[0], "EOA"));
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.true;
  });

  it('Allows a user to sign and prove they are an EOA (v, r, s)', async function() {
    const signature = await getSignedMessage(addrs[0], "EOA");
    const r = signature.slice(0, 66);
    const s = '0x' + signature.slice(66, 130);
    const v = '0x' + signature.slice(130, 132);
    await this.eoaRegistry.connect(addrs[0]).verifySignatureVRS(v, r, s);
    expect(await this.eoaRegistry.isVerifiedEOA(addrs[0].address)).to.be.true;
  });

});

async function getSignedMessage(signer, message) {
  return await signer.signMessage(message);
}