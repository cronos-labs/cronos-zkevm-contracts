// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IBridgehub, L2TransactionRequestTwoBridgesOuter} from "../zksync_contracts_v24/bridgehub/IBridgehub.sol";
import {IL2Bridge} from "../zksync_contracts_v24/bridge/interfaces/IL2Bridge.sol";
import {IGetters} from "../zksync_contracts_v24/state-transition/chain-interfaces/IGetters.sol";
import {ReentrancyGuard} from "../zksync_contracts_v24/common/ReentrancyGuard.sol";
import {UncheckedMath} from "../zksync_contracts_v24/common/libraries/UncheckedMath.sol";


/// @notice BridgeMiddleware
/// The middleware accept to pay the bridge deposit token costs in ETH instead of zkCRO
contract BridgeMiddleware is ReentrancyGuard, Ownable2Step {
    using SafeERC20 for IERC20;
    using UncheckedMath for uint256;

    /// @notice address of the bridgehub
    IBridgehub public bridgeHub;

    /// @notice address of the sharedbridge
    address public sharedBridge;

    /// @notice state contract
    IGetters public cronoszkevm;

    /// @notice chainId
    uint256 chainId;

    /// @notice l2GasLimit
    uint256 l2GasLimit;

    /// @notice l2GasPerPubdataByteLimit
    uint256 l2GasPerPubdataByteLimit;

    /// @notice To set bridge address, only Owner
    function setBridgeParameters(address _bridgeHub, address _sharedBridge) external onlyOwner {
        bridgeHub = IBridgehub(_bridgeHub);
        sharedBridge = _sharedBridge;
    }

    function setCronosZkEVM(address _cronosZkevm) external onlyOwner {
        cronoszkevm = IGetters(_cronosZkevm);
    }

    /// @notice To set base token address, only Owner
    function setChainParameters(uint256 _chainId, uint256 _l2GasLimit, uint256 _l2GasPerPubdataByteLimit) external onlyOwner {
        chainId= _chainId;
        l2GasLimit = _l2GasLimit;
        l2GasPerPubdataByteLimit = _l2GasPerPubdataByteLimit;
    }

    /// @notice To approve bridgehub approval limit for a specific token
    function approveToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).approve(address(bridgeHub), amount);
    }

    /// @notice Transfers tokens from the depositor address to the smart contract address.
    /// @return The difference between the contract balance before and after the transferring of funds.
    function _depositFunds(address _from, IERC20 _token, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    /// @notice Generate a calldata for calling the deposit finalization on the L2 bridge contract
    function _getDepositL2Calldata(
        address _l1Sender,
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) internal view returns (bytes memory) {
        bytes memory gettersData = _getERC20Getters(_l1Token);
        return abi.encodeCall(IL2Bridge.finalizeDeposit, (_l1Sender, _l2Receiver, _l1Token, _amount, gettersData));
    }

    /// @notice Receives and parses (name, symbol, decimals) from the token contract
    function _getERC20Getters(address _token) internal view returns (bytes memory) {
        (, bytes memory data1) = _token.staticcall(abi.encodeCall(IERC20Metadata.name, ()));
        (, bytes memory data2) = _token.staticcall(abi.encodeCall(IERC20Metadata.symbol, ()));
        (, bytes memory data3) = _token.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        return abi.encode(data1, data2, data3);
    }

    function getDepositFee(address _token) external view returns (uint256) {

    }


    /// @notice Deposit tokens to the shared bridge. The middleware accepts to cover the l2 in ETH
    // Need to make sure to pay enough ETH, otherwise the transaction will fail
    // Also make sure that the middleware has set a approval limit high enough for the deposited token
    function deposit(address _token, uint256 _amount) external payable nonReentrant returns (bytes32 canonicalTxHash) {
        require(_token != cronoszkevm.getBaseToken(), "BridgeMiddleware: does not support base token");

        uint256 amount = _depositFunds(msg.sender, IERC20(_token), _amount);
        require(amount == _amount, "BridgeMiddleware: non standard token"); // The token has non-standard transfer logic

        bytes memory callData = _getDepositL2Calldata(address(this), msg.sender, _token, _amount);

        // Compute how many zkCRO the middleware should deposit based on the msg.value
        // No refund is needed, if user overpay, extra zkCRO will be deposited in its account
        uint256 baseDepositInZkCRO = (msg.value * cronoszkevm.baseTokenGasPriceMultiplierNominator()) / cronoszkevm.baseTokenGasPriceMultiplierDenominator();

        canonicalTxHash = bridgeHub.requestL2TransactionTwoBridges(
            L2TransactionRequestTwoBridgesOuter({
                chainId: chainId,
                mintValue: baseDepositInZkCRO,
                l2Value: 0,
                l2GasLimit: l2GasLimit,
                l2GasPerPubdataByteLimit: l2GasPerPubdataByteLimit,
                refundRecipient: msg.sender,
                secondBridgeAddress: sharedBridge,
                secondBridgeValue: 0,
                secondBridgeCalldata: callData
            }));
    }
}
