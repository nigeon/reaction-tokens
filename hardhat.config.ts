import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "solidity-coverage";
import { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.2",
        settings: {
          optimizer: {
            runs: 200,
            enabled: true,
          },
        },
      }
    ],
  },
  networks: {
    hardhat: {
      forking: { 
        url: "https://eth-goerli.alchemyapi.io/v2/8RAnGQRzrDvOYBzM3K_vNdnc52xWa6r6"
      }
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/ac4be4d111564e39bdc4f0cc0e10c7a1",
      chainId: 1,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    ropsten: {
      url: "https://ropsten.infura.io/v3/ac4be4d111564e39bdc4f0cc0e10c7a1",
      chainId: 3,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    goerli: {
      url: "https://goerli.infura.io/v3/ac4be4d111564e39bdc4f0cc0e10c7a1",
      chainId: 5,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    mumbai: {
      url: "https://polygon-mumbai.infura.io/v3/ac4be4d111564e39bdc4f0cc0e10c7a1",
      chainId: 80001,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    matic: {
      url: "https://polygon-mainnet.infura.io/v3/ac4be4d111564e39bdc4f0cc0e10c7a1",
      chainId: 137,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test"
  },
  gasReporter: {
    coinmarketcap: 'a3b86dcc-de63-4a66-b532-56bf7009292c',
    currency: 'USD',
    gasPrice: 18
  }
};

export default config;
