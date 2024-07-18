const { ethers } = require("hardhat");
require("dotenv").config();

const DERIVE_PATH = "m/44'/60'/0'/0/1";
const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const CRONOSZKEVM_ADMIN_ADDRESS = process.env.CRONOSZKEVM_ADMIN_ADDRESS!;
const ORACLE_PRIVATE_KEY = process.env.ORACLE_PRIVATE_KEY!;

async function main() {
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    let oracle_wallet = new ethers.Wallet(ORACLE_PRIVATE_KEY, provider);
    console.log(
        "oracle address:",
        oracle_wallet.address
    );


    const contract = await ethers.getContractAt("CronosZkEVMAdmin", CRONOSZKEVM_ADMIN_ADDRESS, oracle_wallet);
    await contract.setTokenMultiplier(40000,1);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
