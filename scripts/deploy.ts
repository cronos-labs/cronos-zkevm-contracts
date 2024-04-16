// hardhat import should be the first import in the file
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as hardhat from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { Command } from "commander";
import { Wallet, ethers } from "ethers";

import "dotenv/config"

async function main() {
  const program = new Command();
  program.version("0.1.0").name("deploy").description("deploy cronos_zkevm contracts");

  program
    .option("--private-key <private-key>")
    .option("--mnemonic <mneminic>")
    .option("--contract <contractName>")
    .option("--denylist <denylist>")
    .action(async (cmd) => {
      const deployWallet = cmd.privateKey
        ? new Wallet(cmd.privateKey, provider)
        : Wallet.fromMnemonic(
          cmd.mneminic ? cmd.mneminic : process.env.MNEMONIC,
            "m/44'/60'/0'/0/1"
          ).connect(provider);
      console.log(`Using deployer wallet: ${deployWallet.address}`);

      await contractDeployment(deployWallet, cmd);
    });

  await program.parseAsync(process.argv);
}

async function contractDeployment(
  deployWallet: Wallet,
  cmd: any) {
  const contractName = cmd.contract;
  console.log("deploying contract:", contractName);

  console.log("balance: ", ethers.utils.formatEther(await deployWallet.getBalance()));

  const DEPLOYEE = await hardhat.ethers.getContractFactory(contractName, deployWallet);
  const list = cmd.denylist.split(",");
  console.log("denylist", list);
  const contract = await DEPLOYEE.deploy(deployWallet.address, list);
  const receipt = await contract.deployTransaction.wait()

  console.log(`CONTRACT_DEPLOYED_ADDR=${contract.address}`);
  console.log(`CONTRACTS_DEPLOYED_TXHASH=${receipt.transactionHash}`);
}

const provider = web3Provider();

function web3Url() {
  return process.env.ETH_CLIENT_WEB3_URL;
}

function web3Provider() {
  const provider = new ethers.providers.JsonRpcProvider(web3Url());

  // Check that `CHAIN_ETH_NETWORK` variable is set. If not, it's most likely because
  // the variable was renamed. As this affects the time to deploy contracts in localhost
  // scenario, it surely deserves a warning.
  const network = process.env.CHAIN_ETH_NETWORK;
  if (!network) {
    console.log(warning("Network variable is not set. Check if process env CHAIN_ETH_NETWORK is set"));
  }

  // Short polling interval for local network
  if (network === "localhost" || network === "hardhat") {
    provider.pollingInterval = 100;
  }

  return provider;
}


main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });


function warning(arg0: string): any {
  throw new Error(arg0);
}

