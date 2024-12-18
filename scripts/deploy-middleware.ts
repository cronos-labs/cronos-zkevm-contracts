const { ethers } = require("hardhat");
require("dotenv").config();

const L1_PROVIDER = process.env.ETH_CLIENT_WEB3_URL!;
const MIDDLEWARE_MNEMONIC = process.env.MIDDLEWARE_MNEMONIC!;
const DERIVE_PATH = "m/44'/60'/0'/0/1";

const BRIDGE_HUB_ADDRESS = process.env.CONTRACTS_BRIDGEHUB_PROXY_ADDR;
const SHARED_BRIDGE_ADDRESS = process.env.CONTRACTS_L1_SHARED_BRIDGE_PROXY_ADDR;


const CHAIN_ID = process.env.CHAIN_ETH_ZKSYNC_NETWORK_ID;
const ZKSYNC_ADDRESS = process.env.CONTRACTS_DIAMOND_PROXY_ADDR!;

const ETH_SENDER_SENDER_OPERATOR_BLOBS_ETH_ADDR = process.env.ETH_SENDER_SENDER_OPERATOR_BLOBS_ETH_ADDR
const ETH_SENDER_SENDER_OPERATOR_COMMIT_ETH_ADDR = process.env.ETH_SENDER_SENDER_OPERATOR_COMMIT_ETH_ADDR

const REQUIRED_L2_GAS_PRICE_PER_PUBDATA = 800;

async function main() {
    let middleware_wallet = ethers.Wallet.fromMnemonic(MIDDLEWARE_MNEMONIC, DERIVE_PATH);
    const provider = new ethers.providers.JsonRpcProvider(L1_PROVIDER);
    middleware_wallet = middleware_wallet.connect(provider);
    console.log(
        "Deploying middleware contract with the middleware account:",
        middleware_wallet.address
    );

    const BridgeMiddleware = await ethers.getContractFactory("BridgeMiddleware", middleware_wallet);
    console.log("Deploying Bridge middleware...");
    const contract = await BridgeMiddleware.deploy(middleware_wallet.address);

    console.log("Middleware deployed at:", contract.address);

    console.log("Middleware: Set bridge parameters...");
    await contract.setBridgeParameters(BRIDGE_HUB_ADDRESS, SHARED_BRIDGE_ADDRESS);

    console.log("Middleware: Set oracle...");
    await contract.setCronosZkEVM(ZKSYNC_ADDRESS);

    console.log("Middleware: Set chain parameters...");
    await contract.setChainParameters(CHAIN_ID, REQUIRED_L2_GAS_PRICE_PER_PUBDATA);

    console.log("Middleware: Approve zkTCRO...");
    const amount = ethers.utils.parseEther("1000000");
    await contract.approveToken("0x49cE7551514f3c2Bf44B50442765Bb112d0e8204", amount);

    console.log("Middleware: Set ETH Receivers...");
    await contract.setEthReceivers([ETH_SENDER_SENDER_OPERATOR_COMMIT_ETH_ADDR, ETH_SENDER_SENDER_OPERATOR_BLOBS_ETH_ADDR]);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
