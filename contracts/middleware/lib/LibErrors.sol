// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.24;

library LibErrors {
    /// @notice Indicates that the given address is zero
    error InvalidZeroAddress();

    /// @notice Indicates that the given value is zero
    error InvalidNullValue();

    /// @notice Indicates that the given string is empty
    error InvalidEmptyString();
}
