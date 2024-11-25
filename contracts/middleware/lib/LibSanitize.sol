// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import "./LibErrors.sol";

/// @title Lib Sanitize
/// @dev This library helps sanitizing inputs.
library LibSanitize {
    /// @dev Internal utility to sanitize an address and ensure its value is not 0.
    /// @param addressValue The address to verify
    function notZeroAddress(address addressValue) internal pure {
        if (addressValue == address(0)) {
            revert LibErrors.InvalidZeroAddress();
        }
    }

    /// @dev Internal utility to sanitize an uint256 value and ensure its value is not 0.
    /// @param value The value to verify
    function notNullValue(uint256 value) internal pure {
        if (value == 0) {
            revert LibErrors.InvalidNullValue();
        }
    }

    /// @dev Internal utility to sanitize a string value and ensure it's not empty.
    /// @param stringValue The string value to verify
    function notEmptyString(string memory stringValue) internal pure {
        if (bytes(stringValue).length == 0) {
            revert LibErrors.InvalidEmptyString();
        }
    }
}
