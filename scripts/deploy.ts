import { ethers } from "hardhat";
const fs = require("fs");

async function main() {
  // Pre-defined addresses HPA2
  const PCOAdress = "0x2E2Afe3b8Bb81B4aBde568fCa28CB77957682dcF";
  const TokenOwnerAddress = "0x51C4B0487e16186da402daebE06C4cD71b5015c8"; // This is the account which hold all token
  const CLAIM_SIGNER_PREDEFINED_ADDRESS =
    "0xc3fdeaa9e9e5812c9f2c1b2ee7c1b8bf099537d8b8bade7aad445185aa4278ef"; //0xBC4238FbE2CC00C4a093907bCdb4694FEC00882c

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
  const POCStudyContract = await ethers.getContractFactory("POCStudy");
  const ERC20ProxyContract = await ethers.getContractFactory("ERC20Proxy");

  console.log("Deploying...");
  // Deploy the contract
  const ClaimHolder = await ClaimHolderContract.deploy();
  const ClaimVerifier = await ClaimVerifierContract.deploy(ClaimHolder.address);
  const Authenticator = await AuthenticatorContract.deploy(
    ClaimVerifier.address
  );
  const AuthenticatorHelper = await AuthenticatorHelperContract.deploy(
    Authenticator.address
  );
  const DDR = await DDRContract.deploy(
    ClaimHolder.address,
    AuthenticatorHelper.address
  );
  const Patient = await PatientContract.deploy(
    DDR.address,
    AuthenticatorHelper.address
  );
  const POCStudy = await POCStudyContract.deploy(
    Patient.address,
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
  console.log("POCStudy deployed to:", POCStudy.address);
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
      POCStudy: {
        address: POCStudy.address,
        abi: require("../artifacts/contracts/lockdata/POCStudy.sol/POCStudy.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/POCStudy.sol/POCStudy.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/POCStudy.sol/POCStudy.json")
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
