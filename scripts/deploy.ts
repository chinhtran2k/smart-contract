import { ethers } from "hardhat";
const fs = require("fs");

async function main() {
  const AuthenticatorContract = await ethers.getContractFactory(
    "Authenticator"
  );
  const AuthenticatorHelperContract = await ethers.getContractFactory(
    "AuthenticatorHelper"
  );
  const DDRContract = await ethers.getContractFactory("DDR");
  const PatientContract = await ethers.getContractFactory("Patient");
  const PharmacyContract = await ethers.getContractFactory("Pharmacy");

  console.log("Deploying...");

  // TODO: Please add verifier
  const Authenticator = await AuthenticatorContract.deploy(
    "0x171B05abAAb452D4662F7f0f1a40976D42ee75FB"
  );
  const AuthenticatorHelper = await AuthenticatorHelperContract.deploy(
    Authenticator.address
  );
  const DDR = await DDRContract.deploy(AuthenticatorHelper.address);
  const Patient = await PatientContract.deploy(
    DDR.address,
    AuthenticatorHelper.address
  );
  const Pharmacy = await PharmacyContract.deploy(
    DDR.address,
    AuthenticatorHelper.address
  );

  console.log(`Authenticator deployed to: ${Authenticator.address}`);
  console.log(
    `AuthenticatorHelper deployed to: ${AuthenticatorHelper.address}`
  );
  console.log(`DDR deployed to: ${DDR.address}`);
  console.log(`Patient deployed to: ${Patient.address}`);
  console.log(`Pharmacy deployed to: ${Pharmacy.address}`);

  // create config file
  fs.writeFileSync(
    "../config.json",
    JSON.stringify({
      Authenticator: {
        address: Authenticator.address,
        abi: require("../artifacts/contracts/utils/Authenticator.sol/Authenticator.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/utils/Authenticator.sol/Authenticator.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/utils/Authenticator.sol/Authenticator.json")
            .contractName,
      },
      AuthenticatorHelper: {
        address: AuthenticatorHelper.address,
        abi: require("../artifacts/contracts/utils/Authenticator.sol/AuthenticatorHelper.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/utils/Authenticator.sol/AuthenticatorHelper.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/utils/Authenticator.sol/AuthenticatorHelper.json")
            .contractName,
      },
      DDR: {
        address: DDR.address,
        abi: require("../artifacts/contracts/lockdata/DDR.sol/DDR.json").abi,
        bytecode: require("../artifacts/contracts/lockdata/DDR.sol/DDR.json")
          .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/DDR.sol/DDR.json")
            .contractName,
      },
      Patient: {
        address: Patient.address,
        abi: require("../artifacts/contracts/lockdata/Patient.sol/Patient.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/Patient.sol/Patient.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/Patient.sol/Patient.json")
            .contractName,
      },
      Pharmacy: {
        address: Pharmacy.address,
        abi: require("../artifacts/contracts/lockdata/Pharmacy.sol/Pharmacy.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/Pharmacy.sol/Pharmacy.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/Pharmacy.sol/Pharmacy.json")
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
