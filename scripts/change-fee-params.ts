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

    const contract = await ethers.getContractAt("CronosZkEVMAdmin", CRONOSZKEVM_ADMIN_ADDRESS, admin_wallet);
    let new_fee_param = {
        pubdataPricingMode: "Validium",
        batchOverheadL1Gas: 750000,
        maxPubdataPerBatch: 1000000,
        maxL2GasPerBatch: 80000000,
        priorityTxMaxPubdata: 1000000,
        minimalL2GasPrice:500000000000
    };

    await contract.changeFeeParams(new_fee_param);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
