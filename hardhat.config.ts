import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const PRIVATE_KEY =
  "147ba01ee975ff771486759b75206a128babdef687aed85c15c13dbb28f038cf";

const config: HardhatUserConfig = {
  solidity: "0.8.7",
  networks: {
    test: {
      url: `http://10.1.4.148:8545/`,
      accounts: [`${PRIVATE_KEY}`],
    },
    ganache: {
      url: `http://localhost:7545/`,
      accounts: [`${PRIVATE_KEY}`],
    },
  },
};

export default config;
