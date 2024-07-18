const { ethers } = require("hardhat");
require("dotenv").config();

const ADMIN_MNEMONIC = process.env.ADMIN_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";
const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const CRONOSZKEVM_ADMIN_ADDRESS = process.env.CRONOSZKEVM_ADMIN_ADDRESS!;


async function main() {
    let admin_wallet = ethers.Wallet.fromMnemonic(ADMIN_MNEMONIC, DERIVE_PATH);
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    admin_wallet = admin_wallet.connect(provider);
    console.log(
        "using admin account",
        admin_wallet.address
    );



    const contract = await ethers.getContractAt("CronosZkEVMAdmin", CRONOSZKEVM_ADMIN_ADDRESS, admin_wallet);

    const oracleAddress = ""

    await contract.setOracle(oracleAddress);

    console.log(
        "oracle role set"
    );

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
