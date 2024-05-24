import { Wallet, ethers } from "ethers";

export const provider = web3Provider();

export function web3Url() {
  return process.env.ETH_CLIENT_WEB3_URL;
}

export function web3Provider() {
  const provider = new ethers.providers.JsonRpcProvider(web3Url());

  // Check that `CHAIN_ETH_NETWORK` variable is set. If not, it's most likely because
  // the variable was renamed. As this affects the time to deploy contracts in localhost
  // scenario, it surely deserves a warning.
  const network = process.env.CHAIN_ETH_NETWORK;
  if (!network) {
    console.log(warning("Network variable is not set. Check if process env CHAIN_ETH_NETWORK is set"));
  }

  // Short polling interval for local network
  if (network === "localhost" || network === "hardhat") {
    provider.pollingInterval = 100;
  }

  return provider;
}

function warning(arg0: string): any {
    throw new Error(arg0);
}

export function getWallet(cmd: any): Wallet {
    const wallet = cmd.privateKey
    ? new Wallet(cmd.privateKey, provider)
    : Wallet.fromMnemonic(
      cmd.mnemonic ? cmd.mnemonic : process.env.MNEMONIC,
        "m/44'/60'/0'/0/1"
      ).connect(provider);
  console.log(`Using wallet: ${wallet.address}`);
  return wallet;
}
  

