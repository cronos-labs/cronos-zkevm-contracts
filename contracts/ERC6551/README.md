## Cronos zkEVM ERC6551

Contracts for ERC6551(Non-fungible Token Bound Accounts) implementation of Cronos zkEVM.

zkSync currently does not support ERC-1167 due to compatibility issues with EVM bytecode and opcodes. Since ERC-6551 relies on ERC-1167, we have to  workaround these incompatibility. As a result, this implementation of ERC-6551 is not fully adhere to the original spec.


The ERC-6551 contracts are synchronized from: cronos-labs/agent-fun/contracts/libs