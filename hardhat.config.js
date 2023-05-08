require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-truffle5");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("solidity-coverage");
require("@nomicfoundation/hardhat-foundry");

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1500
      }
    }
  },
  networks: {
    hardhat: {
    },
    localhost: {
      url: "http://localhost:8545"
    }
  },
  mocha: {
    timeout: 100000000
  },
  gasReporter: {
    enabled: true
  }
};
