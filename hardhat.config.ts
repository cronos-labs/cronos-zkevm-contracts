import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import "hardhat-typechain";
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names";
import { subtask, task } from "hardhat/config";

const path = require("path");
// eslint-disable-next-line @typescript-eslint/no-var-requires
const systemParams = require("./SystemConfig.json");

const prodConfig = {
  UPGRADE_NOTICE_PERIOD: 0,
  // PRIORITY_EXPIRATION: 101,
  // NOTE: Should be greater than 0, otherwise zero approvals will be enough to make an instant upgrade!
  SECURITY_COUNCIL_APPROVALS_FOR_EMERGENCY_UPGRADE: 1,
  PRIORITY_TX_MAX_GAS_LIMIT: 72000000,
  DEPLOY_L2_BRIDGE_COUNTERPART_GAS_LIMIT: 10000000,
  DUMMY_VERIFIER: false,
  ERA_CHAIN_ID: 324,
  BLOB_VERSIONED_HASH_GETTER_ADDR: "0x0000000000000000000000000000000000001337",
};

const localConfig = {
  ...prodConfig,
  UPGRADE_NOTICE_PERIOD: 0,
  DUMMY_VERIFIER: true,
  EOA_GOVERNOR: true,
  ERA_CHAIN_ID: 9,
  ERA_DIAMOND_PROXY: "address(0)",
  ERA_TOKEN_BEACON_ADDRESS: "address(0)",
  ERA_ERC20_BRIDGE_ADDRESS: "address(0)",
  ERA_WETH_ADDRESS: "address(0)",
  ERA_WETH_BRIDGE_ADDRESS: "address(0)",
  ERC20_BRIDGE_IS_BASETOKEN_BRIDGE: true,
};

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999999,
      },
      outputSelection: {
        "*": {
          "*": ["storageLayout"],
        },
      },
      evmVersion: "cancun",
    },
  },
  contractSizer: {
    runOnCompile: false,
  },
  paths: {
    sources: "./contracts",
  },
  solpp: {
    defs: (() => {

      const defs = localConfig;
      return {
        ...systemParams,
        ...defs,
      };
    })(),
  },
  etherscan: {
    apiKey: process.env.MISC_ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: true,
  },
};

task("solpp", "Preprocess Solidity source files").setAction(async (_, hre) =>
    hre.run(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS)
);

// Add a subtask that sets the action for the TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS task
subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
  const paths = await runSuper();
  return paths.filter((p: any) => !p.includes("test/foundry/") && !p.includes("lib/forge-std/"));
});