// hardhat import should be the first import in the file
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as hardhat from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { Command } from "commander";

import "dotenv/config"
import * as util from './util';


async function main() {
    const program = new Command();
    program.version("0.1.0").name("deny-list-update").description("update denylist");
  
    program
      .option('--private-key <private-key>')
      .option('--mnemonic <mneminic>')
      .option('--remove', 'remove address')
      .requiredOption('--list <addresses-to-be-added-to-deny-list>')
      .requiredOption("--contract <contract-address>")
      .action(async (cmd) => {
        const wallet = util.getWallet(cmd);

        var args: any[] = [];
        const list = cmd.list ? cmd.list.split(",") : [];
        const add = cmd.remove ? false : true;
        args = [list, add];

        const CONTRACT = await hardhat.ethers.getContractAt("TransactionFiltererDenyList", cmd.contract, wallet);
        console.log(`The input args of updateDenyList: ${args}`);
        const tx = await CONTRACT.updateDenyList(...args);
        const receipt = await tx.wait();
        console.log("Tx hash:", receipt.transactionHash);

        for (const addr of list) {
          const newargs = [addr, addr, 0, 0, 0, addr];
          const allowed = await CONTRACT.isTransactionAllowed(...newargs);
          console.log("The tx from address:", addr, "is", allowed? "allowed": "not allowed");
        }
      });
  
    await program.parseAsync(process.argv);
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });        
