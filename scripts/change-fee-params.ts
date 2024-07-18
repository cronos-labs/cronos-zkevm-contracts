const { ethers } = require("hardhat");
require("dotenv").config();

const DERIVE_PATH = "m/44'/60'/0'/0/1";
const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const CRONOSZKEVM_ADMIN_ADDRESS = process.env.CRONOSZKEVM_ADMIN_ADDRESS!;
const FEE_ADMIN_PRIVATE_KEY = process.env.FEE_ADMIN_PRIVATE_KEY!;

async function main() {
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    let fee_wallet = new ethers.Wallet(FEE_ADMIN_PRIVATE_KEY, provider);
    console.log(
        "oracle address:",
        fee_wallet.address
    );


    const contract = await ethers.getContractAt("CronosZkEVMAdmin", CRONOSZKEVM_ADMIN_ADDRESS, fee_wallet);

    // Set overhead batch to zero to take account only the minimalL2GasPrice
    let new_fee_param = {
        pubdataPricingMode: 1,
        batchOverheadL1Gas: 0,
        maxPubdataPerBatch: 750000,
        maxL2GasPerBatch: 200000000,
        priorityTxMaxPubdata: 750000,
        minimalL2GasPrice:2000000000000
    }

    await contract.changeFeeParams(new_fee_param);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
