// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

bytes32 constant CREATE2_PREFIX = keccak256("zksyncCreate2");

library ZksyncCreate2 {
    /// @notice Copied from https://github.com/matter-labs/era-contracts/blob/84d5e3716f645909e8144c7d50af9dd6dd9ded62/system-contracts/contracts/ContractDeployer.sol#L99
    ///
    /// @notice Calculates the address of a deployed contract via create2
    /// @param _sender The account that deploys the contract.
    /// @param _bytecodeHash The correctly formatted hash of the bytecode.
    /// @param _salt The create2 salt.
    /// @param _inputHash The hash of the constructor data.
    /// @return newAddress The derived address of the account.
    function getNewAddressCreate2(
        address _sender,
        bytes32 _bytecodeHash,
        bytes32 _salt,
        bytes32 _inputHash
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                CREATE2_PREFIX,
                bytes32(uint256(uint160(_sender))),
                _salt,
                _bytecodeHash,
                _inputHash
            )
        );

        return address(uint160(uint256(hash)));
    }
}
