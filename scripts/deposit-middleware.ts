const { ethers } = require("hardhat");
require("dotenv").config();

const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const MIDDLEWARE_MNEMONIC = process.env.MIDDLEWARE_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";
const MIDDLEWARE_ADDR = process.env.CONTRACTS_MIDDLEWARE_ADDR!;
const SHARED_BRIDGE_ADDRESS = process.env.CONTRACTS_L1_SHARED_BRIDGE_PROXY_ADDR;

const L2_GAS_LIMIT=2000000;

async function main() {
    let middleware_wallet = ethers.Wallet.fromMnemonic(MIDDLEWARE_MNEMONIC, DERIVE_PATH);
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    middleware_wallet = middleware_wallet.connect(provider);

    const contract = await ethers.getContractAt("BridgeMiddleware", MIDDLEWARE_ADDR, middleware_wallet);

    // Approve ERC20 for middleware to spend
    const ERC20_ADDR = "0x04AcE6131ad84046B2b4997F6Db10b7F5eE82BcE";
    //const ERC20_ADDR = "0x0000000000000000000000000000000000000001";
    const depositAmount = "1"
    const amount = ethers.utils.parseEther(depositAmount);
    const erc20contract = await ethers.getContractAt("ERC20", ERC20_ADDR, middleware_wallet);
    console.log("Approve : ", depositAmount, "of ", ERC20_ADDR);
    await erc20contract.approve(MIDDLEWARE_ADDR, amount);

    // Deposit ERC20 (the L2 fee is hardcoded to 0.001 ETH but can be optimised by calling l2 fee estimation)
    const destination = "0x6ac694E69Ea40060a7c811AC128AB9a1E1418975";
    console.log("Deposit : ", depositAmount, "of ", ERC20_ADDR);

    //await contract.deposit(destination, ERC20_ADDR, amount, L2_GAS_LIMIT, {
    //    value: ethers.utils.parseEther("0.002")
    //});

    await contract.approvalAndDeposit(destination, ERC20_ADDR, amount, L2_GAS_LIMIT, {
        value: ethers.utils.parseEther("0.001")
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
