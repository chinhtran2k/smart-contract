const CONFIG = require("../config/config.json");
const { exec } = require("child_process");
const request = require("request");
const Web3 = require("web3");
const fs = require("fs");
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
        url: "http://192.168.2.113:4000/verify_smart_contract/contract_verifications",
        headers: {
          Accept:
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
          "Accept-Language": "en-US,en;q=0.9,vi;q=0.8",
          "Cache-Control": "max-age=0",
          Connection: "keep-alive",
          "Content-Type": "application/x-www-form-urlencoded",
          Origin: "http://192.168.2.113:4000",
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
          "smart_contract[optimization]": "false",
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

const flattenContract = async (contractPath: any) => {
  return new Promise((resolve, reject) => {
    exec(
      `${__dirname}/../node_modules/.bin/hardhat flatten ${__dirname}/../${contractPath} > ${__dirname}/../flatten/flated.sol`,
      (error: any, stdout: any, stderr: any) => {
        console.log("Verify contract", contractPath);
        const str = fs.readFileSync(__dirname + "/../flatten/flated.sol").toString();
        const removeSPDX = str
          .split("// SPDX-License-Identifier: MIT")
          .join("")
          .split("pragma solidity ^0.8.0;")
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
  const ClaimHolder = "contracts/ClaimHolder.sol";
  const ClaimVerifier = "contracts/ClaimVerifier.sol";

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
  ];

  for (let i = 0; i < listContract.length; i++) {
    const contract = listContract[i];
    const contractSourceCode = await flattenContract(contract.path);
    const web3 = new Web3();
    // console.log("contract abi: ", contract.abi[0]);
    // console.log("contract input: ", contract.input);
    // const abiParams = web3.eth.abi
    //   .encodeFunctionCall(contract.abi[0].inputs);
    // console.log("abi params: ", abiParams);
    await verifyRequest(
      contract.address,
      contract.contractName,
      contractSourceCode,
      ""
    );

    await delay(3000);
  }
}

main();
