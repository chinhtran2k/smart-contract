const CONFIG = require("../config/config.json");
const { exec } = require("child_process");
const request = require("request");
const Web3 = require("web3");
const fs = require("fs");

const URL_BLOCKSCOUT = "http://10.1.4.148:4000";
const URL_BLOCKSCOUT_TTC = "http://192.168.2.8:4000";

const PCOAdress = "0x08114a50bAF075F67BCCCcc7Fe5189db54E8D7f8";
const TokenOwnerAddress = "0x51C4B0487e16186da402daebE06C4cD71b5015c8"; // This is the account which hold all token
const DEFAULT_AWARD__VALUE_PREDEFINED = 100;

const verifyRequest = async (
  addressHash: string,
  name: string,
  contractSourceCode: any,
  constructorArguments = ""
) => {
  console.log("Verify contract", addressHash, name, constructorArguments);
  return new Promise((resolve, reject) => {
    request(
      {
        method: "POST",
        url:
          URL_BLOCKSCOUT_TTC + "/verify_smart_contract/contract_verifications",
        headers: {
          Accept:
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Accept-Language": "en-US,en;q=0.9,vi;q=0.8",
          "Cache-Control": "max-age=0",
          Connection: "keep-alive",
          "Content-Type": "application/x-www-form-urlencoded",
          Origin: URL_BLOCKSCOUT_TTC,
          "Upgrade-Insecure-Requests": "1",
          "User-Agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36",
        },
        form: {
          "smart_contract[address_hash]": addressHash,
          "smart_contract[name]": name,
          "smart_contract[nightly_builds]": "false",
          "smart_contract[compiler_version]": "v0.8.7+commit.e28d00a7",
          "smart_contract[evm_version]": "default",
          "smart_contract[optimization]": "true",
          "smart_contract[optimization_runs]": "200",
          "smart_contract[contract_source_code]": contractSourceCode,
          "smart_contract[autodetect_constructor_args]": "false",
          "smart_contract[constructor_arguments]": constructorArguments,
          "external_libraries[library1_name]": "",
          "external_libraries[library1_address]": "",
          "external_libraries[library2_name]": "",
          "external_libraries[library2_address]": "",
          "external_libraries[library3_name]": "",
          "external_libraries[library3_address]": "",
          "external_libraries[library4_name]": "",
          "external_libraries[library4_address]": "",
          "external_libraries[library5_name]": "",
          "smart_contract[library5_address]": "",
        },
      },
      function (error: any, response: any) {
        if (error) console.log("Error", addressHash, name);
        else resolve(response.body);
      }
    );
  });
};

const flattenContract = async (contractPath: string) => {
  return new Promise((resolve, reject) => {
    exec(
      `${__dirname}/../node_modules/.bin/hardhat flatten ${__dirname}/../${contractPath} > ${__dirname}/../flatten/flatten.sol`,
      (error: any, stdout: any, stderr: any) => {
        console.log("Verify contract", contractPath);
        const str = fs
          .readFileSync(__dirname + "/../flatten/flatten.sol")
          .toString();
        const removeSPDX = str
          .split("// SPDX-License-Identifier: MIT")
          .join("")
          .split("pragma solidity ^0.8.0;")
          .join("")
          .split("pragma solidity ^0.8.1;")
          .join("");
        const idxStart = removeSPDX.indexOf(
          "// Sources flattened with hardhat"
        );
        const processedStr = `// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n${removeSPDX.substring(
          idxStart,
          removeSPDX.length
        )}`;
        resolve(processedStr);
      }
    );
  });
};

const delay = (ms: any) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const ClaimHolder = "contracts/DID/ClaimHolder.sol";
  const ClaimVerifier = "contracts/DID/ClaimVerifier.sol";
  const Authenticator = "contracts/utils/Authenticator.sol";
  const AuthenticatorHelper = "contracts/utils/Authenticator.sol";
  const DDR = "contracts/lockdata/DDR.sol";
  const Patient = "contracts/lockdata/Patient.sol";
  const POCStudy = "contracts/lockdata/POCStudy.sol";
  const ERC20Proxy = "contracts/erc20Proxy/ERC20Proxy.sol";

  const listContract = [
    {
      path: ClaimHolder,
      ...CONFIG.ClaimHolder,
      input: [],
    },
    {
      path: ClaimVerifier,
      ...CONFIG.ClaimVerifier,
      input: [CONFIG.ClaimHolder.address],
    },
    {
      path: Authenticator,
      ...CONFIG.Authenticator,
      input: [CONFIG.ClaimVerifier.address],
    },
    {
      path: AuthenticatorHelper,
      ...CONFIG.AuthenticatorHelper,
      input: [CONFIG.Authenticator.address],
    },
    {
      path: DDR,
      ...CONFIG.DDR,
      input: [CONFIG.ClaimHolder.address, CONFIG.Authenticator.address],
    },
    {
      path: Patient,
      ...CONFIG.Patient,
      input: [CONFIG.DDR.address, CONFIG.Authenticator.address],
    },
    {
      path: POCStudy,
      ...CONFIG.POCStudy,
      input: [CONFIG.Patient.address, CONFIG.Authenticator.address],
    },
    {
      path: ERC20Proxy,
      ...CONFIG.ERC20Proxy,
      input: [
        PCOAdress,
        TokenOwnerAddress,
        CONFIG.DDR.address,
        DEFAULT_AWARD__VALUE_PREDEFINED,
      ],
    },
  ];

  for (let i = 0; i < listContract.length; i++) {
    const contract = listContract[i];
    const contractSourceCode = await flattenContract(contract.path);
    const web3 = new Web3();
    // console.log("contract abi: ", contract.abi[0].inputs);
    // console.log("contract input: ", contract.input);
    const abiParams = web3.eth.abi
      .encodeParameters(contract.abi[0].inputs, contract.input)
      .replace("0x", "");
    // console.log("abi params: ", abiParams);
    await verifyRequest(
      contract.address,
      contract.contractName,
      contractSourceCode,
      abiParams
    );

    await delay(3000);
  }
}

main();
