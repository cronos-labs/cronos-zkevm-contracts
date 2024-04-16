# Smart contracts for cronos zkevm 


## Compile smart contracts

`` yarn build ``

### Testing

Similarly, to run tests in Foundry execute `yarn test:foundry`.
**If you don't have the foundry installed, please see [Foundry installation](https://book.getfoundry.sh/getting-started/installation).**
**Learn how to use Forge-Std with the [📖 Foundry Book (Forge-Std Guide)](https://book.getfoundry.sh/forge/forge-std.html).**

## Deploy contracts

`` yarn deploy --contract [contract name] [--contract-argument-name] [contract-argument-value] ``

For example: ``yarn deploy --contract TransactionFiltererDenyList --denylist "0x1234567890123456789012345678901234567890,0x1111111111111111111111111111111111111111"``