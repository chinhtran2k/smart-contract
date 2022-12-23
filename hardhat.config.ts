import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";

const PRIVATE_KEY =
  "24118478a12cd8e910ec3ae69edc8bda17c70754dd00d13f28dda0aa0f8644bb";
const CLAIM_SIGNER_PREDEFINED_ADDRESS =
  "187bcbef9261e6c7eaefd8368e2b930a8bd7335cf541d8a05e9337beaf4c5f89";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    test: {
      url: `http://10.1.4.148:8545`,
      accounts: [`${PRIVATE_KEY}`, `${CLAIM_SIGNER_PREDEFINED_ADDRESS}`],
    },
    testTTC: {
      url: `http://192.168.2.8:8545`,
      accounts: [`${PRIVATE_KEY}`, `${CLAIM_SIGNER_PREDEFINED_ADDRESS}`],
    },
    ganache: {
      url: `http://localhost:7545`,
      accounts: [`${PRIVATE_KEY}`, `${CLAIM_SIGNER_PREDEFINED_ADDRESS}`],
    },
    product: {
      url: `http://hpa3-production-blc-alb-1798551139.ap-northeast-1.elb.amazonaws.com`,
      accounts: [`${PRIVATE_KEY}`, `${CLAIM_SIGNER_PREDEFINED_ADDRESS}`],
    },
    staging: {
      url: `http://52.197.45.128:8545`,
      accounts: [`${PRIVATE_KEY}`, `${CLAIM_SIGNER_PREDEFINED_ADDRESS}`],
    },
  },
};

export default config;
