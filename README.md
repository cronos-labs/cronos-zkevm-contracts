# Smart contracts for cronos zkevm 


## Compile smart contracts

`` yarn build ``

### Testing

Similarly, to run tests in Foundry execute `yarn test:foundry`.
**If you don't have the foundry installed, please see [Foundry installation](https://book.getfoundry.sh/getting-started/installation).**
**Learn how to use Forge-Std with the [📖 Foundry Book (Forge-Std Guide)](https://book.getfoundry.sh/forge/forge-std.html).**

## Deploy denylist contract

`` yarn deploy-denylist --contract [=CONTRACT-NAME] [--args [=CONTRACT-CONSTRUCTOR-ARGUMENTS] ``

For example: ``yarn deploy-denylist --contract TransactionFiltererDenyList --args "addr1,addr2"``

## Update denylist

`` yarn update-denylist --contract [=CONTRACT-ADDRESS] --list [=Addresses should add or remove from the denylist] [--remove] ``

To add some addresses to the denylist: ``yarn deploy-denylist --contract [contract-deployed-address] --list "addr1,addr2,..."``
To add remove addresses to the denylist: ``yarn deploy-denylist --contract [contract-deployed-address] --list "addr1,addr2,... --remove"``