import { ethers } from "hardhat";
const fs = require("fs");

async function main() {
  const ClaimHolderContract = await ethers.getContractFactory("ClaimHolder");
  const ClaimVerifierContract = await ethers.getContractFactory("ClaimVerifier");
  // console.log("Deploying ClaimHolder...", ClaimHolderContract);

  const ClaimHolder = await ClaimHolderContract.deploy();
  const ClaimVerifier = await ClaimVerifierContract.deploy(ClaimHolder.address);

  console.log(`ClaimHolder deployed to: ${ClaimHolder.address}`);
  console.log(`ClaimVerifier deployed to: ${ClaimVerifier.address}`);

  // create config file
  fs.writeFileSync(
    "./config/config.json",
    JSON.stringify({
      ClaimHolder: {
        address: ClaimHolder.address,
        abi: require("../artifacts/contracts/ClaimHolder.sol/ClaimHolder.json").abi,
        contractName: require("../artifacts/contracts/ClaimHolder.sol/ClaimHolder.json")
          .contractName,
      },
      ClaimVerifier: {
        address: ClaimVerifier.address,
        abi: require("../artifacts/contracts/ClaimVerifier.sol/ClaimVerifier.json").abi,
        contractName: require("../artifacts/contracts/ClaimVerifier.sol/ClaimVerifier.json")
          .contractName,
      },
    })
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
