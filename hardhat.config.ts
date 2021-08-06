import 'dotenv/config';
import "@nomiclabs/hardhat-waffle";
import "hardhat-gas-reporter";
import "hardhat-contract-sizer";
import "solidity-coverage";
import '@openzeppelin/hardhat-upgrades';
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
        url: 'https://polygon-mumbai.g.alchemy.com/v2/' + process.env.ALCHEMY_TOKEN,
      },
    },
    meh: {
      url: `http://127.0.0.1:8545/`,
      chainId: 31337,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECTID}`,
      chainId: 1,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_PROJECTID}`,
      chainId: 3,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECTID}`,
      chainId: 5,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_APIKEY}`,
      chainId: 80001,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
    matic: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_PROJECTID}`,
      chainId: 137,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : "remote",
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test"
  },
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_APIKEY,
    currency: 'USD',
    gasPrice: 18
  }
};

export default config;
