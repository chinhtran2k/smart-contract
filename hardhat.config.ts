import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

// const PRIVATE_KEY = ""

const config: HardhatUserConfig = {
  solidity: "0.8.7",
  networks: {
    test: {
      url: `http://10.1.4.148:8545/`,
      // accounts: [`${PRIVATE_KEY}`],
    },
  },
};

export default config;