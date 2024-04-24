// hardhat import should be the first import in the file
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as hardhat from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { Command } from "commander";
import { Contract, Wallet, ethers } from "ethers";

import "dotenv/config"
import * as util from './util';

async function main() {
  const program = new Command();
  program.version("0.1.0").name("deploy").description("deploy cronos_zkevm contracts");

  program
    .option("--private-key <private-key>")
    .option("--mnemonic <mneminic>")
    .option("--contract <contractName>")
    .option("--args <contract-constructor-arguments>")
    .action(async (cmd) => {
      const deployWallet = util.getWallet(cmd);
      await contractDeployment(deployWallet, cmd);
    });

  await program.parseAsync(process.argv);
}

async function contractDeployment(
  deployWallet: Wallet,
  cmd: any) {
  const contractName = cmd.contract;
  console.log("deploying contract:", contractName);

  const DEPLOYEE = await hardhat.ethers.getContractFactory(contractName, deployWallet);

  // Construct the arguments if the contract needs the constructor arguments.
  var args: any[] = [];
  if (contractName == "TransactionFiltererDenyList") {
    const list = cmd.args ? cmd.args.split(",") : [];
    args = [deployWallet.address, list];
  }

  const contract = await DEPLOYEE.deploy(...args);
  const receipt = await contract.deployTransaction.wait()

  console.log(`CONTRACT_DEPLOYED_ADDR=${contract.address}`);
  console.log(`CONTRACTS_DEPLOYED_TXHASH=${receipt.transactionHash}`);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });


