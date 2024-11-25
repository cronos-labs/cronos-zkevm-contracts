// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

address constant IMMUTABLE_SIMULATOR_ADDRESS = 0x0000000000000000000000000000000000008005;

/**
 * Docs: https://docs.zksync.io/build/developer-reference/era-contracts/system-contracts#immutables
 * Source code: https://github.com/matter-labs/era-contracts/blob/84d5e3716f645909e8144c7d50af9dd6dd9ded62/system-contracts/contracts/ImmutableSimulator.sol#L28
 */
interface IImmutableSimulator {
    function getImmutable(
        address dest,
        uint256 index
    ) external view returns (bytes32);
}
