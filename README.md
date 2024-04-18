# Smart contracts for cronos zkevm 


## Compile smart contracts

`` yarn build ``

### Testing

Similarly, to run tests in Foundry execute `yarn test:foundry`.
**If you don't have the foundry installed, please see [Foundry installation](https://book.getfoundry.sh/getting-started/installation).**
**Learn how to use Forge-Std with the [📖 Foundry Book (Forge-Std Guide)](https://book.getfoundry.sh/forge/forge-std.html).**

## Deploy denylist contract

`` yarn deploy-denylist --contract [=CONTRACT-NAME] [--args [=CONTRACT-CONSTRUCTOR-ARGUMENTS] ``

For example: ``yarn deploy-denylist --contract TransactionFiltererDenyList --args "0x1234567890123456789012345678901234567890,0x1111111111111111111111111111111111111111"``