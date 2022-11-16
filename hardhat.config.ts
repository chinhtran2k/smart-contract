import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY =
  "24118478a12cd8e910ec3ae69edc8bda17c70754dd00d13f28dda0aa0f8644bb";

const config: HardhatUserConfig = {
  solidity: "0.8.7",
  networks: {
    test: {
      url: `http://10.1.4.148:8545/`,
      accounts: [`${PRIVATE_KEY}`],
    },
    testTTC: {
      url: `http://192.168.2.8:8545/`,
      accounts: [`${PRIVATE_KEY}`],
    },
    ganache: {
      url: `http://localhost:7545/`,
      accounts: [`${PRIVATE_KEY}`],
    },
  },
};

export default config;
