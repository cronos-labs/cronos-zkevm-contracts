// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * Update the `ACCOUNT_PROXY_BYTECODE_HASH` constant when changing this contract
 *
 * Modified from OpenZeppelin's Proxy contract
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Proxy.sol
 *
 * In ERC-6551 spec, AccountProxy is a Minimal Proxy (ERC-1667) and the token data
 * (chainId, tokenContract, and tokenId) is appended to the AccountProxy's bytecode for later access.
 *
 * However, there're two issues:
 *  1. zkSync EVM does not support Minimal Proxy (ERC-1667) due to bytecode compatibility issues.
 *  2. zkSync EVM does not allow smart contracts to access contract bytecode directly.
 *
 * We manage to work around the above limitations by:
 *  1. Opt out Minimal Proxy for Account Proxy (We used a custom Proxy)
 *  2. Store the token data in the AccountProxy's immutables.
 *
 * It’s important to note that immutables in the zkSync EVM works differently than in EVM equivalent envs.
 * In zkSync EVM, immutables are not stored directly in the contract's bytecode. Instead, they are handled
 * by the zk compiler and stored in the system contract ImmutableSimulator's storage.
 * Immutables can be accessed through ImmutableSimulator.
 *
 * Docs: https://docs.zksync.io/build/developer-reference/era-contracts/system-contracts#immutables
 */
contract AccountProxy {
    address internal immutable implementation;
    bytes32 internal immutable salt;
    uint256 internal immutable chainId;
    address internal immutable tokenContract;
    uint256 internal immutable tokenId;

    constructor(
        address _implementation,
        bytes32 _salt,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId
    ) {
        implementation = _implementation;
        salt = _salt;
        chainId = _chainId;
        tokenContract = _tokenContract;
        tokenId = _tokenId;
    }

    fallback() external payable {
        address impl = implementation;
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0, calldatasize())
            // Delegatecall method of the implementation contract returns 0 on error
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            // Get the size of the last return data
            let size := returndatasize()
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0, size)
            // Depending on the result value
            switch result
            case 0 {
                // End execution and revert state changes
                revert(ptr, size)
            }
            default {
                // Return data with length of size at pointers position
                return(ptr, size)
            }
        }
    }
}
