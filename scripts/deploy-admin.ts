const { ethers } = require("hardhat");
require("dotenv").config();

const ADMIN_MNEMONIC = process.env.ADMIN_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";
const ZKSYNC_ADDRESS = process.env.CONTRACTS_DIAMOND_PROXY_ADDR!;
const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;

async function main() {
    let admin_wallet = ethers.Wallet.fromMnemonic(ADMIN_MNEMONIC, DERIVE_PATH);
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    admin_wallet = admin_wallet.connect(provider);
    console.log(
        "Deploying admin contract with the admin account:",
        admin_wallet.address
    );

    const CronosZkEVMAdmin = await ethers.getContractFactory("CronosZkEVMAdmin", admin_wallet);

    const contract = await CronosZkEVMAdmin.deploy(ZKSYNC_ADDRESS, admin_wallet.address);

    console.log("CronosZkEVMAdmin deployed at:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
