import { ethers, hardhatArguments } from "hardhat";
import Web3 from "web3";
const fs = require("fs");
const web3 = new Web3();

async function main() {
  const deployers = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployers[0].address);
  console.log("Account balance:", (await deployers[0].getBalance()).toString());

  // Pre-defined addresses EDC
  const PCOAdress = "0x08114a50bAF075F67BCCCcc7Fe5189db54E8D7f8";
  // const PCOAdress = "0xDa46c687723751af0e7266A8A32eBe34E21070F0";
  const TokenOwnerAddress = "0x51C4B0487e16186da402daebE06C4cD71b5015c8"; // This is the account which hold all token
  const CLAIM_SIGNER_PREDEFINED_ADDRESS =
    "0x187bcbef9261e6c7eaefd8368e2b930a8bd7335cf541d8a05e9337beaf4c5f89"; //0xBC4238FbE2CC00C4a093907bCdb4694FEC00882c
  const EXECUTION_PREDEFINED_ADDRESS =
    "0x155c1c7686bd19ce88adb6a4af3cbc3a3caf489f62d0e06b901cb6d2a3400719"; //0xB981494fFE0dBd29137ff6bAa8bC494c827CFf3D
  const DEFAULT_AWARD_VALUE_PREDEFINED = 100;

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
  const DDRBranchContract = await ethers.getContractFactory("DDRBranch");
  const DisclosureBranchContract = await ethers.getContractFactory(
    "DisclosureBranch"
  );
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
    Authenticator.address
  );
  const DDRBranch = await DDRBranchContract.deploy(
    DDR.address,
    Authenticator.address
  );
  const DisclosureBranch = await DisclosureBranchContract.deploy(
    DDR.address,
    Authenticator.address
  );
  const Patient = await PatientContract.deploy(
    ClaimHolder.address,
    DDRBranch.address,
    DisclosureBranch.address,
    Authenticator.address
  );
  const POCStudy = await POCStudyContract.deploy(
    Patient.address,
    Authenticator.address
  );
  const ERC20Proxy = await ERC20ProxyContract.deploy(
    PCOAdress,
    TokenOwnerAddress,
    DDR.address,
    DEFAULT_AWARD_VALUE_PREDEFINED
  );

  console.log("ClaimHolder deployed to:", ClaimHolder.address);
  console.log("ClaimVerifier deployed to:", ClaimVerifier.address);
  console.log("Authenticator deployed to:", Authenticator.address);
  console.log("AuthenticatorHelper deployed to:", AuthenticatorHelper.address);
  console.log("DDR deployed to:", DDR.address);
  console.log("DDRBranch deployed to:", DDRBranch.address);
  console.log("DisclosureBranch deployed to:", DisclosureBranch.address);
  console.log("Patient deployed to:", Patient.address);
  console.log("POCStudy deployed to:", POCStudy.address);
  console.log("ERC20Proxy deployed to:", ERC20Proxy.address);

  // Add pre-defined keySigner to ClaimHolder
  const signerAccount = await web3.eth.accounts.privateKeyToAccount(
    CLAIM_SIGNER_PREDEFINED_ADDRESS
  );
  const hashedAddress = await web3.utils.keccak256(signerAccount.address);
  console.log("> Added pre-defined keySigner for ClaimHolder: ", hashedAddress);
  await ClaimHolder.addKey(hashedAddress, 3, 1);

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
      DDRBranch: {
        address: DDRBranch.address,
        abi: require("../artifacts/contracts/lockdata/DDRBranch.sol/DDRBranch.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/DDRBranch.sol/DDRBranch.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/DDRBranch.sol/DDRBranch.json")
            .contractName,
      },
      DisclosureBranch: {
        address: DisclosureBranch.address,
        abi: require("../artifacts/contracts/lockdata/DisclosureBranch.sol/DisclosureBranch.json")
          .abi,
        bytecode:
          require("../artifacts/contracts/lockdata/DisclosureBranch.sol/DisclosureBranch.json")
            .bytecode,
        contractName:
          require("../artifacts/contracts/lockdata/DisclosureBranch.sol/DisclosureBranch.json")
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
