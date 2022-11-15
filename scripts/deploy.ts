import { ethers } from "hardhat";
import { PromiseOrValue } from "../typechain-types/common";
const fs = require("fs");

async function main() {
  // Pre-defined addresses HPA2
  const PCOAdress = "";
  const TokenOwnerAddress = ""; // This is the account which hold all token

  // Assign the contract factory
  const ClaimHolderContract = await ethers.getContractFactory("ClaimHolder");
  const ClaimVerifierContract = await ethers.getContractFactory(
    "ClaimVerifier"
  );
  const AuthenticatorContract = await ethers.getContractFactory(
    "Authenticator"
  );
  const AuthenticatorHelperContract = await ethers.getContractFactory(
    "AuthenticatorHelper"
  );
  const DDRContract = await ethers.getContractFactory("DDR");
  const PatientContract = await ethers.getContractFactory("Patient");
  const PharmacyContract = await ethers.getContractFactory("Pharmacy");
  const ERC20ProxyContract = await ethers.getContractFactory("ERC20Proxy");

  console.log("Deploying...");
  // Deploy the contract
  const ClaimHolder = await ClaimHolderContract.deploy();
  const ClaimVerifier = await ClaimVerifierContract.deploy(ClaimHolder.address);
  const claimVerifierAdress: PromiseOrValue<string> = ClaimVerifier.address;
  const Authenticator = await AuthenticatorContract.deploy(claimVerifierAdress);
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
  const ERC20Proxy = await ERC20ProxyContract.deploy(
    PCOAdress,
    TokenOwnerAddress,
    DDR.address
  );
  // Set token proxy for DDR level
  DDR.setERC20Proxy(ERC20Proxy.address);

  console.log("ClaimHolder deployed to:", ClaimHolder.address);
  console.log("ClaimVerifier deployed to:", ClaimVerifier.address);
  console.log("Authenticator deployed to:", Authenticator.address);
  console.log("AuthenticatorHelper deployed to:", AuthenticatorHelper.address);
  console.log("DDR deployed to:", DDR.address);
  console.log("Patient deployed to:", Patient.address);
  console.log("Pharmacy deployed to:", Pharmacy.address);
  console.log("ERC20Proxy deployed to:", ERC20Proxy.address);

  // create config file
  fs.writeFileSync(
    "./config/config.json",
    JSON.stringify({
      ClaimHolder: {
        address: ClaimHolder.address,
        abi: require("../artifacts/contracts/DID/ClaimHolder.sol/ClaimHolder.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/DID/ClaimHolder.sol/ClaimHolder.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/DID/ClaimHolder.sol/ClaimHolder.json")
            .contractName,
      },
      ClaimVerifier: {
        address: ClaimVerifier.address,
        abi: require("../artifacts/contracts/DID/ClaimVerifier.sol/ClaimVerifier.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/DID/ClaimVerifier.sol/ClaimVerifier.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/DID/ClaimVerifier.sol/ClaimVerifier.json")
            .contractName,
      },
      Identity: {
        address: "",
        abi: require("../artifacts/contracts/DID/Identity.sol/Identity.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/DID/Identity.sol/Identity.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/DID/Identity.sol/Identity.json")
            .contractName,
      },
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
      ERC20Proxy: {
        address: ERC20Proxy.address,
        abi: require("../artifacts/contracts/erc20Proxy/ERC20Proxy.sol/ERC20Proxy.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/erc20Proxy/ERC20Proxy.sol/ERC20Proxy.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/erc20Proxy/ERC20Proxy.sol/ERC20Proxy.json")
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
