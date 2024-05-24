// hardhat import should be the first import in the file
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import * as hardhat from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { Command } from "commander";
require("dotenv").config();

const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const MIDDLEWARE_MNEMONIC = process.env.MIDDLEWARE_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";
const MIDDLEWARE_ADDR = process.env.CONTRACTS_MIDDLEWARE_ADDR!;
async function main() {
    const program = new Command();
    program.version("0.1.0").name("approve-token-middleware").description("approve token middleware");

    program
        .requiredOption("--contract <contractName>")
        .requiredOption("--amount <amount>")
        .action(async (cmd) => {
            let middleware_wallet = hardhat.ethers.Wallet.fromMnemonic(MIDDLEWARE_MNEMONIC, DERIVE_PATH);
            const provider = new hardhat.ethers.providers.JsonRpcProvider(L1_PROVIDER);
            middleware_wallet = middleware_wallet.connect(provider);

            const contract = await hardhat.ethers.getContractAt("BridgeMiddleware", MIDDLEWARE_ADDR, middleware_wallet);


            const ERC20_ADDR = cmd.contract;
            const approvalAmount = cmd.amount
            console.log("Set bridge approval for token: ", ERC20_ADDR);

            const approval_limit = hardhat.ethers.utils.parseEther(approvalAmount);
            await contract.approveToken(ERC20_ADDR, approval_limit)
        });

    await program.parseAsync(process.argv);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error("Error:", err);
        process.exit(1);
    });