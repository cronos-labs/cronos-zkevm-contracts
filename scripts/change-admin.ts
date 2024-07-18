const { ethers } = require("hardhat");
require("dotenv").config();

const ADMIN_MNEMONIC = process.env.ADMIN_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";
const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const CRONOSZKEVM_ADMIN_ADDRESS = process.env.CRONOSZKEVM_ADMIN_ADDRESS!;
const NEW_CRONOSZKEVM_ADMIN_ADDRESS = process.env.NEW_CRONOSZKEVM_ADMIN_ADDRESS!;
const ZKSYNC_ADDRESS = process.env.CONTRACTS_DIAMOND_PROXY_ADDR!;

async function main() {
    let admin_wallet = ethers.Wallet.fromMnemonic(ADMIN_MNEMONIC, DERIVE_PATH);
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    admin_wallet = admin_wallet.connect(provider);

    // set new admin
    const contract = await ethers.getContractAt("CronosZkEVMAdmin", CRONOSZKEVM_ADMIN_ADDRESS, admin_wallet);
    const tx = await contract.setPendingAdmin(NEW_CRONOSZKEVM_ADMIN_ADDRESS);
    console.log("set pending admin tx ", tx.hash);
    await tx.wait();

    // accept admin
    const new_contract = await ethers.getContractAt("CronosZkEVMAdmin", NEW_CRONOSZKEVM_ADMIN_ADDRESS, admin_wallet);
    const tx2 = await new_contract.acceptAdmin();
    console.log("accept pending admin tx ", tx2.hash);
    await tx2.wait();


    const getterFacet = await ethers.getContractAt("contracts/zksync_contracts_v24/state-transition/chain-deps/facets/Getters.sol:GettersFacet", ZKSYNC_ADDRESS, admin_wallet);
    let admin = await getterFacet.getAdmin();
    console.log(
        "current admin:",
        admin
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
