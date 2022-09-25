require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  defaultNetwork: "matic",
  networks: {
    hardhat: {
    },
    matic: {
      url: "https://polygon-rpc.com",
      accounts: ['da3ee88803b6a7d758f47b19e704199014d3d458fa2bf4573e181663f2d343a4']
    }
  },
  etherscan: {
    apiKey: 'M458C64RH2YSXC5WZNEAYP6CZDR9FTZ88U'
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
}
