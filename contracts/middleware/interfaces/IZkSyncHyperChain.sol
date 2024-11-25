// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

interface IZkSyncHyperChain {
    /// @return baseTokenGasPriceMultiplierNominator, used to compare the baseTokenPrice to ether for L1->L2 transactions
    function baseTokenGasPriceMultiplierNominator() external view returns (uint128);

    /// @return baseTokenGasPriceMultiplierDenominator, used to compare the baseTokenPrice to ether for L1->L2 transactions
    function baseTokenGasPriceMultiplierDenominator() external view returns (uint128);
}
