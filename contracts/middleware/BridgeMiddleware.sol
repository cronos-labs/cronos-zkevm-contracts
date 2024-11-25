// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import {LibSanitize} from "./lib/LibSanitize.sol";
import {IBridgehub, L2TransactionRequestTwoBridgesOuter} from "../zksync_contracts_v25/bridgehub/IBridgehub.sol";
import {IZkSyncHyperchain} from "../zksync_contracts_v25/state-transition/chain-interfaces/IZkSyncHyperchain.sol";

/// @notice BridgeMiddleware
///
/// Bridging ETH and ERC20 token from L1(Ethereum) to L2 (Hyperchain) without the need for users to hold the Hyperchain base token.
///
/// How it works:
/// 1. The middleware accepts ETH instead of the Hyperchain base token (zkCRO) to cover L2 transaction costs.
///     With this middleware, the L2 transaction gas fee is still paid in zkCRO, but the middleware swaps ETH provided
///     by the user to zkCRO behind the scenes, eliminating the need for users to hold zkCRO in their wallets.
/// 2. The middleware needs to be funded with zkCRO.
/// 3. Over time, the funded zkCRO will be consumed and will need to be replenished.
/// 4. Additionally, the middleware will accumulate ETH over time, which can be withdrawn by the `WithdrawAdmin`.
/// 5. The middelware relies on the baseTokenGasPriceMultipliers exposed by the hperchain to convert between ETH and zkCRO.
contract BridgeMiddleware is ReentrancyGuard, AccessControlEnumerable {
    using SafeERC20 for IERC20;

    error UnsupportedToken();
    error WithdrawEthFailed();
    error InsufficientEthBalance();
    error InsufficientBaseTokenBalance();
    error LowL2GasFee();
    error AllowanceNotZero();

    /// @notice Emitted when withdraws ETH from `this` contract to the `to` address.
    event WithdrawEth(address indexed to, uint256 amount);
    /// @notice Emitted when withdraws base token from `this` contract to the `to` address.
    event WithdrawBaseToken(address indexed to, uint256 amount);
    /// @notice Emitted when the treasury address is updated.
    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);

    address private constant ETH_TOKEN_ADDRESS = address(1);
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    /// @notice address of the bridgehub
    IBridgehub public bridgehub;
    /// @notice The hyperchain id
    uint256 public chainId;
    /// @notice The address where base tokens and ETH will be withdrawn to.
    address public treasury;

    constructor(uint256 _chainId, address _bridgehub, address _admin, address _withdrawer, address _treasury) {
        LibSanitize.notZeroAddress(_bridgehub);
        LibSanitize.notZeroAddress(_admin);
        LibSanitize.notZeroAddress(_withdrawer);
        LibSanitize.notZeroAddress(_treasury);

        chainId = _chainId;
        bridgehub = IBridgehub(_bridgehub);
        treasury = _treasury;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(WITHDRAW_ROLE, _withdrawer);
    }

    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        LibSanitize.notZeroAddress(_treasury);
        address oldTreasury = treasury;

        treasury = _treasury;
        emit SetTreasury(oldTreasury, _treasury);
    }

    /// `this` contract accumulates ETH over time, which can be withdrawn by the `WithdrawAdmin`.
    ///
    /// @param _amount The amount of ETH to withdraw
    function withdrawEth(uint256 _amount) external nonReentrant onlyRole(WITHDRAW_ROLE) {
        LibSanitize.notNullValue(_amount);

        if (_amount > address(this).balance) {
            revert InsufficientEthBalance();
        }

        (bool success,) = payable(treasury).call{value: _amount}("");
        if (!success) {
            revert WithdrawEthFailed();
        }

        emit WithdrawEth(treasury, _amount);
    }

    /// `this` contract need to be funded with base token to cover the L2 transaction cost for users.
    ///
    /// This method is used for the `WithdrawAdmin` to withdraw/migrate the base token from `this` contract.
    ///
    /// @param _amount The amount of base token to withdraw
    function withdrawBaseToken(uint256 _amount) external nonReentrant onlyRole(WITHDRAW_ROLE) {
        LibSanitize.notNullValue(_amount);

        IERC20 baseToken = IERC20(bridgehub.baseToken(chainId));

        if (_amount > baseToken.balanceOf(address(this))) {
            revert InsufficientBaseTokenBalance();
        }

        baseToken.safeTransfer(treasury, _amount);

        emit WithdrawBaseToken(treasury, _amount);
    }

    /// @param _amount The amount of base token to approve to the shared bridge
    function approveBaseToken(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 baseToken = IERC20(bridgehub.baseToken(chainId));

        address sharedBridge = address(bridgehub.sharedBridge());

        if (_amount != 0 && baseToken.allowance(address(this), sharedBridge) > 0) {
            revert AllowanceNotZero();
        }

        baseToken.approve(sharedBridge, _amount);
    }

    /// @notice Generate a calldata for calling the deposit finalization on the L2 bridge contract
    function _getDepositL2Calldata(address _l2Receiver, address _l1Token, uint256 _amount)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_l1Token, _amount, _l2Receiver);
    }

    /// @notice Convert ETH to the base token base on the multipliers
    function convertToBaseTokenAmount(uint256 _ethAmount) public view returns (uint256) {
        IZkSyncHyperchain hyperChain = IZkSyncHyperchain(bridgehub.getHyperchain(chainId));
        uint256 n = hyperChain.baseTokenGasPriceMultiplierNominator();
        uint256 d = hyperChain.baseTokenGasPriceMultiplierDenominator();

        return (_ethAmount * n) / d;
    }

    /// @notice Convert base token to ETH base on the multipliers
    function convertToEthAmount(uint256 _baseTokenAmount) public view returns (uint256) {
        IZkSyncHyperchain hyperChain = IZkSyncHyperchain(bridgehub.getHyperchain(chainId));
        uint256 n = hyperChain.baseTokenGasPriceMultiplierNominator();
        uint256 d = hyperChain.baseTokenGasPriceMultiplierDenominator();

        return (_baseTokenAmount * d) / n;
    }

    /// @notice estimate the cost of L2 tx in base token.
    /// @param _l1GasPrice The gas price on L1
    /// @param _l2GasLimit The estimated L2 gas limit
    /// @param _l2GasPerPubdataByteLimit The price for each pubdata byte in L2 gas
    /// @return The price of L2 gas in the base token
    function l2TransactionBaseCost(uint256 _l1GasPrice, uint256 _l2GasLimit, uint256 _l2GasPerPubdataByteLimit)
        public
        view
        returns (uint256)
    {
        return bridgehub.l2TransactionBaseCost(chainId, _l1GasPrice, _l2GasLimit, _l2GasPerPubdataByteLimit);
    }

    /// @notice estimate the cost of L2 tx in ETH.
    /// @param _l1GasPrice The gas price on L1
    /// @param _l2GasLimit The estimated L2 gas limit
    /// @param _l2GasPerPubdataByteLimit The price for each pubdata byte in L2 gas
    /// @return The price of L2 gas in the base token
    function l2TransactionEthCost(uint256 _l1GasPrice, uint256 _l2GasLimit, uint256 _l2GasPerPubdataByteLimit)
        external
        view
        returns (uint256)
    {
        uint256 baseCost = l2TransactionBaseCost(_l1GasPrice, _l2GasLimit, _l2GasPerPubdataByteLimit);
        return convertToEthAmount(baseCost);
    }

    /// Bridge ETH or ERC20 from L1 (Ethereum) to L2 (hyperchain)
    ///
    /// @param _l2Receiver The L2 receiver address
    /// @param _token The l1Token to bridge, can be either ETH or ERC20 token, but not the base token
    /// @param _amount The amount of tokens to bridge
    /// @param _l2GasLimit The L2 tx gas limit
    /// @param _l2GasPerPubdataByteLimit The L2 tx gas per pubdata byte limit
    /// @param _refundRecipient The address for receiving the L2 gas fee refund
    /// @return canonicalTxHash The L2 canonical tx hash
    function bridge(
        address _l2Receiver,
        address _token,
        uint256 _amount,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        address _refundRecipient
    ) external payable nonReentrant returns (bytes32 canonicalTxHash) {
        LibSanitize.notZeroAddress(_l2Receiver);
        LibSanitize.notZeroAddress(_token);
        LibSanitize.notNullValue(_amount);
        LibSanitize.notNullValue(_l2GasLimit);
        LibSanitize.notNullValue(_l2GasPerPubdataByteLimit);
        LibSanitize.notZeroAddress(_refundRecipient);

        // BridgeMiddle does not support bridging the base token
        // For bridging base token, use `Bridgehub.requestL2TransactionDirect` instead.
        if (_token == bridgehub.baseToken(chainId)) {
            revert UnsupportedToken();
        }

        if (_token == ETH_TOKEN_ADDRESS) {
            canonicalTxHash = _bridgeEth(_l2Receiver, _amount, _l2GasLimit, _l2GasPerPubdataByteLimit, _refundRecipient);
        } else {
            canonicalTxHash =
                _bridgeErc20(_l2Receiver, _token, _amount, _l2GasLimit, _l2GasPerPubdataByteLimit, _refundRecipient);
        }
    }

    /// Bridge the ETH from L1 (Ethereum) to L2 (hyperchain)
    function _bridgeEth(
        address _l2Receiver,
        uint256 _amount,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        address _refundRecipient
    ) internal returns (bytes32 canonicalTxHash) {
        if (msg.value <= _amount) {
            revert LowL2GasFee();
        }

        uint256 feeInEth = msg.value - _amount;

        uint256 feeInBaseToken = convertToBaseTokenAmount(feeInEth);
        bytes memory callData = _getDepositL2Calldata(_l2Receiver, ETH_TOKEN_ADDRESS, 0);

        canonicalTxHash = bridgehub.requestL2TransactionTwoBridges{value: _amount}(
            L2TransactionRequestTwoBridgesOuter({
                chainId: chainId,
                mintValue: feeInBaseToken,
                l2Value: 0,
                l2GasLimit: _l2GasLimit,
                l2GasPerPubdataByteLimit: _l2GasPerPubdataByteLimit,
                refundRecipient: _refundRecipient,
                secondBridgeAddress: address(bridgehub.sharedBridge()),
                secondBridgeValue: _amount,
                secondBridgeCalldata: callData
            })
        );
    }

    /// Bridge ERC20 from L1 (Ethereum) to L2 (hyperchain)
    function _bridgeErc20(
        address _l2Receiver,
        address _token,
        uint256 _amount,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        address _refundRecipient
    ) internal returns (bytes32 canonicalTxHash) {
        if (msg.value == 0) {
            revert LowL2GasFee();
        }
        uint256 feeInBaseToken = convertToBaseTokenAmount(msg.value);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        address sharedBridge = address(bridgehub.sharedBridge());
        IERC20(_token).approve(sharedBridge, _amount);

        bytes memory callData = _getDepositL2Calldata(_l2Receiver, _token, _amount);

        canonicalTxHash = bridgehub.requestL2TransactionTwoBridges(
            L2TransactionRequestTwoBridgesOuter({
                chainId: chainId,
                mintValue: feeInBaseToken,
                l2Value: 0,
                l2GasLimit: _l2GasLimit,
                l2GasPerPubdataByteLimit: _l2GasPerPubdataByteLimit,
                refundRecipient: _refundRecipient,
                secondBridgeAddress: sharedBridge,
                secondBridgeValue: 0,
                secondBridgeCalldata: callData
            })
        );
    }
}
