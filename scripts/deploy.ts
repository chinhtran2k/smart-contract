import { ethers } from "hardhat";
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Pre-defined addresses EDC
  const PCOAdress = "0x08114a50bAF075F67BCCCcc7Fe5189db54E8D7f8";
  const TokenOwnerAddress = "0x51C4B0487e16186da402daebE06C4cD71b5015c8"; // This is the account which hold all token
  const CLAIM_SIGNER_PREDEFINED_ADDRESS =
    "0xc3fdeaa9e9e5812c9f2c1b2ee7c1b8bf099537d8b8bade7aad445185aa4278ef"; //0xBC4238FbE2CC00C4a093907bCdb4694FEC00882c
  const EXECUTION_PREDEFINED_ADDRESS =
    "0x155c1c7686bd19ce88adb6a4af3cbc3a3caf489f62d0e06b901cb6d2a3400719"; //0xB981494fFE0dBd29137ff6bAa8bC494c827CFf3D
  const DEFAULT_AWARD__VALUE_PREDEFINED = 100;

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
  const ProviderContract = await ethers.getContractFactory("Provider");
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
    Authenticator.address
  );
  const Patient = await PatientContract.deploy(
    DDR.address,
    ClaimHolder.address,
    Authenticator.address
  );
  const Provider = await ProviderContract.deploy(
    Authenticator.address,
    ClaimHolder.address
  );
  const POCStudy = await POCStudyContract.deploy(
    Patient.address,
    Provider.address,
    Authenticator.address
  );
  const ERC20Proxy = await ERC20ProxyContract.deploy(
    PCOAdress,
    TokenOwnerAddress,
    DDR.address,
    DEFAULT_AWARD__VALUE_PREDEFINED
  );

  console.log("ClaimHolder deployed to:", ClaimHolder.address);
  console.log("ClaimVerifier deployed to:", ClaimVerifier.address);
  console.log("Authenticator deployed to:", Authenticator.address);
  console.log("AuthenticatorHelper deployed to:", AuthenticatorHelper.address);
  console.log("DDR deployed to:", DDR.address);
  console.log("Patient deployed to:", Patient.address);
  console.log("Provider deployed to:", Provider.address);
  console.log("POCStudy deployed to:", POCStudy.address);
  console.log("ERC20Proxy deployed to:", ERC20Proxy.address);

  // Add pre-defined keySigner to ClaimHolder
  console.log(
    "> Added pre-defined keySigner for ClaimHolder: ",
    CLAIM_SIGNER_PREDEFINED_ADDRESS
  );
  await ClaimHolder.addKey(CLAIM_SIGNER_PREDEFINED_ADDRESS, 3, 1);

  // Add pre-defined keyExecution to ClaimHolder
  console.log(
    "> Added pre-defined keyExecution for ClaimHolder: ",
    EXECUTION_PREDEFINED_ADDRESS
  );
  await ClaimHolder.addKey(EXECUTION_PREDEFINED_ADDRESS, 2, 1);

  // Set token proxy for DDR level
  console.log("> Seted token proxy for DDR: ", ERC20Proxy.address);
  await DDR.setERC20Proxy(ERC20Proxy.address);

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
      Provider: {
        address: Provider.address,
        abi: require("../artifacts/contracts/lockdata/Provider.sol/Provider.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/Provider.sol/Provider.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/Provider.sol/Provider.json")
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
