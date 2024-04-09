// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IBridgehub, L2TransactionRequestTwoBridgesOuter} from "../bridgehub/IBridgehub.sol";
import {IL2Bridge} from "../bridge/interfaces/IL2Bridge.sol";
import {ReentrancyGuard} from "../common/ReentrancyGuard.sol";
import {UncheckedMath} from "../common/libraries/UncheckedMath.sol";

import {BridgehubL2TransactionRequest, L2Message, L2Log, TxStatus} from "../common/Messaging.sol";

struct ChainParams{
    /// @dev chainId
    uint256 chainId;

    uint256 l2GasPerPubdataByteLimit;

    address baseToken;

    uint256 batchOverheadL1Gas;

    uint256 maxPubdataPerBatch;

    uint256 minimalL2GasPrice;

    uint256 maxL2GasPerBatch;
}

contract BridgeMiddleware is ReentrancyGuard, Ownable2Step {
    using SafeERC20 for IERC20;
    using UncheckedMath for uint256;

    /// @dev address of the bridgehub
    IBridgehub public bridgeHub;

    /// @dev address of the sharedbridge
    address public sharedBridge;

    /// @dev parameters of the l2 hyperchain
    ChainParams public params;


    /// @notice to avoid parity hack
    constructor() reentrancyGuardInitializer {}

    /// @notice To set bridge hub, only Owner
    function setBridgeParameters(address _bridgeHub, address _sharedBridge) external onlyOwner {
        bridgeHub = IBridgehub(_bridgeHub);
        sharedBridge = _sharedBridge;
    }

    /// @notice To set base token, only Owner
    function setChainParameters(ChainParams calldata _params) external onlyOwner {
        params= _params;
    }

    /// @notice sets bridgehub approval limit for zkCRO
    function approvezkCRO(uint256 amount) external onlyOwner {
         IERC20(params.baseToken).approve(address(bridgeHub), amount);
    }

    /// @dev Transfers tokens from the depositor address to the smart contract address.
    /// @return The difference between the contract balance before and after the transferring of funds.
    function _depositFunds(address _from, IERC20 _token, uint256 _amount) internal returns (uint256) {
        uint256 balanceBefore = _token.balanceOf(address(this));
        _token.safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = _token.balanceOf(address(this));

        return balanceAfter - balanceBefore;
    }

    /// @dev Generate a calldata for calling the deposit finalization on the L2 bridge contract
    function _getDepositL2Calldata(
        address _l1Sender,
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) internal view returns (bytes memory) {
        bytes memory gettersData = _getERC20Getters(_l1Token);
        return abi.encodeCall(IL2Bridge.finalizeDeposit, (_l1Sender, _l2Receiver, _l1Token, _amount, gettersData));
    }

    /// @dev Receives and parses (name, symbol, decimals) from the token contract
    function _getERC20Getters(address _token) internal view returns (bytes memory) {
        (, bytes memory data1) = _token.staticcall(abi.encodeCall(IERC20Metadata.name, ()));
        (, bytes memory data2) = _token.staticcall(abi.encodeCall(IERC20Metadata.symbol, ()));
        (, bytes memory data3) = _token.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        return abi.encode(data1, data2, data3);
    }

    /// @notice
    function TransactionBaseCostInETH(
        uint256 _gasPrice,
        uint256 _l2GasLimit
    ) internal view returns (uint256) {
        uint256 l2GasPrice = _deriveL2GasPriceInETH(_gasPrice, params.l2GasPerPubdataByteLimit);
        return l2GasPrice * _l2GasLimit;
    }

    function _deriveL2GasPriceInETH(uint256 _l1GasPrice, uint256 _gasPerPubdata) internal view returns (uint256) {
        uint256 batchOverhead = params.batchOverheadL1Gas * _l1GasPrice;
        uint256 fullPubdataPrice = batchOverhead / params.maxPubdataPerBatch;
        uint256 l2GasPriceInETH = params.minimalL2GasPrice + batchOverhead / params.maxL2GasPerBatch;
        uint256 minL2GasPriceETH = (fullPubdataPrice + _gasPerPubdata - 1) / _gasPerPubdata;

        return Math.max(l2GasPriceInETH, minL2GasPriceETH);
    }


    /// @notice
    function bridgeToken(address _token, uint256 _amount, uint256 _l2GasLimit) external payable nonReentrant returns (bytes32 canonicalTxHash) {
        require(_token != params.baseToken, "BridgeMiddleware: does not support base token");

        uint256 amount = _depositFunds(msg.sender, IERC20(_token), _amount);
        require(amount == _amount, "BridgeMiddleware: non standard token"); // The token has non-standard transfer logic

        uint256 baseCostInEth = TransactionBaseCostInETH(tx.gasprice, _l2GasLimit);
        require(msg.value >= baseCostInEth, "BridgeMiddleware: payment too low");

        bytes memory callData = _getDepositL2Calldata(address(this), msg.sender, _token, _amount);

        uint256 baseCost = bridgeHub.l2TransactionBaseCost(params.chainId, tx.gasprice, _l2GasLimit, _l2GasLimit);

        bridgeHub.requestL2TransactionTwoBridges(
            L2TransactionRequestTwoBridgesOuter({
                chainId: params.chainId,
                mintValue: baseCost,
                l2Value: 0,
                l2GasLimit: _l2GasLimit,
                l2GasPerPubdataByteLimit: params.l2GasPerPubdataByteLimit,
                refundRecipient: msg.sender,
                secondBridgeAddress: sharedBridge,
                secondBridgeValue: 0,
                secondBridgeCalldata: callData
            }));
    }
}
