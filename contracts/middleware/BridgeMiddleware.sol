// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IBridgehub, L2TransactionRequestTwoBridgesOuter} from "../zksync_contracts_v24/bridgehub/IBridgehub.sol";
import {IL2Bridge} from "../zksync_contracts_v24/bridge/interfaces/IL2Bridge.sol";
import {IGetters} from "../zksync_contracts_v24/state-transition/chain-interfaces/IGetters.sol";
import {UncheckedMath} from "../zksync_contracts_v24/common/libraries/UncheckedMath.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";



/// @notice BridgeMiddleware
/// The middleware accept to pay the bridge deposit token costs in ETH instead of zkCRO
contract BridgeMiddleware is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using UncheckedMath for uint256;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant WITHDRAWER = keccak256("WITHDRAWER");

    /// @notice address of the bridgehub
    IBridgehub public bridgeHub;

    /// @notice address of the sharedbridge
    address public sharedBridge;

    /// @notice state contract
    IGetters public cronoszkevm;

    /// @notice address that can receive ETH
    address payable[] public ethReceivers;

    /// @notice chainId
    uint256 chainId;

    /// @notice l2GasLimit
    uint256 l2GasLimit;

    /// @notice l2GasPerPubdataByteLimit
    uint256 l2GasPerPubdataByteLimit;

    /// @notice ETH address
    address constant ETH_TOKEN_ADDRESS = address(1);

    constructor(address _admin){
        address admin = _admin;
        if (admin == address(0)) {
            admin = msg.sender;
        }
        // ACL
        _grantRole(ADMIN, admin);
        _grantRole(WITHDRAWER, admin);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(WITHDRAWER, ADMIN);
    }

    /*//////////////////////////////////////////////////////////////
                    ACL
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer admin role to a new address
    function transferAdmin (
        address _newAdmin
    ) public onlyRole(ADMIN) {
        grantRole(ADMIN, _newAdmin);
        grantRole(WITHDRAWER, _newAdmin);
        revokeRole(ADMIN, msg.sender);
        revokeRole(WITHDRAWER, msg.sender);
    }

    /// @notice Set oracle role
    function setWithdrawer (
        address _withdrawer
    ) public onlyRole(ADMIN) {
        grantRole(WITHDRAWER, _withdrawer);
    }

    /// @notice Revoke oracle role
    function revokeWithdrawer (
        address _withdrawer
    ) public onlyRole(ADMIN) {
        revokeRole(WITHDRAWER, _withdrawer);
    }


    /*//////////////////////////////////////////////////////////////
                Setter
    //////////////////////////////////////////////////////////////*/

    /// @notice To set bridge address, only Owner
    function setBridgeParameters(address _bridgeHub, address _sharedBridge) external onlyRole(ADMIN) {
        bridgeHub = IBridgehub(_bridgeHub);
        sharedBridge = _sharedBridge;
    }

    function setCronosZkEVM(address _cronosZkevm) external onlyRole(ADMIN) {
        cronoszkevm = IGetters(_cronosZkevm);
    }

    /// @notice To set base token address, only Owner
    function setChainParameters(uint256 _chainId, uint256 _l2GasLimit, uint256 _l2GasPerPubdataByteLimit) external onlyRole(ADMIN) {
        chainId= _chainId;
        l2GasLimit = _l2GasLimit;
        l2GasPerPubdataByteLimit = _l2GasPerPubdataByteLimit;
    }

    /// @notice Set the list of address able to receive ETH
    function setEthReceivers(address payable[] memory _ethReceivers) external onlyRole(ADMIN) {
        ethReceivers = _ethReceivers;
    }

    /// @notice To approve share bridge approval limit for a specific token
    function approveToken(address _token, uint256 amount) external onlyRole(ADMIN) {
        IERC20(_token).approve(address(sharedBridge), amount);
    }

    /// @notice Withdraw ETH from middleware to a selected receiver (only operator)
    function withdrawETH(uint256 _amount, uint256 _index) external onlyRole(WITHDRAWER) {
        require(ethReceivers.length > _index, "wrong index");
        ethReceivers[_index].transfer(_amount);
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
        address _l2Receiver,
        address _l1Token,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return abi.encode(_l1Token, _amount, _l2Receiver);
    }

    /// @notice Deposit tokens to the shared bridge. The middleware accepts to cover the l2 in ETH
    // Need to make sure to pay enough ETH, otherwise the transaction will fail
    // Also make sure that the middleware has set a approval limit high enough for the deposited token
    function deposit(address _dest, address _token, uint256 _amount) external nonReentrant payable returns (bytes32 canonicalTxHash) {
        require(_token != cronoszkevm.getBaseToken(), "BridgeMiddleware: does not support base token");

        if (_token != ETH_TOKEN_ADDRESS) {
            uint256 amount = _depositFunds(msg.sender, IERC20(_token), _amount);
            require(amount == _amount, "BridgeMiddleware: non standard token"); // The token has non-standard transfer logic
            bytes memory callData = _getDepositL2Calldata(_dest, _token, _amount);
            // Compute how many zkCRO the middleware should deposit based on the msg.value
            // No refund is needed, if user overpay, extra zkCRO will be deposited in its account
            uint256 feeInZkCRO = (msg.value * cronoszkevm.baseTokenGasPriceMultiplierNominator()) / cronoszkevm.baseTokenGasPriceMultiplierDenominator();

            canonicalTxHash = bridgeHub.requestL2TransactionTwoBridges(
                L2TransactionRequestTwoBridgesOuter({
                    chainId: chainId,
                    mintValue: feeInZkCRO,
                    l2Value: 0,
                    l2GasLimit: l2GasLimit,
                    l2GasPerPubdataByteLimit: l2GasPerPubdataByteLimit,
                    refundRecipient: _dest,
                    secondBridgeAddress: sharedBridge,
                    secondBridgeValue: 0,
                    secondBridgeCalldata: callData
                }));
        } else {
            require(msg.value > _amount, "BridgeMiddleware: not enough deposited amount to cover l2 fee");
            uint256 fee = msg.value - _amount;
            uint256 feeInZkCRO = (fee * cronoszkevm.baseTokenGasPriceMultiplierNominator()) / cronoszkevm.baseTokenGasPriceMultiplierDenominator();
            bytes memory callData = _getDepositL2Calldata(_dest, _token, 0);

            canonicalTxHash = bridgeHub.requestL2TransactionTwoBridges{value: _amount}(
                L2TransactionRequestTwoBridgesOuter({
                    chainId: chainId,
                    mintValue: feeInZkCRO,
                    l2Value: 0,
                    l2GasLimit: l2GasLimit,
                    l2GasPerPubdataByteLimit: l2GasPerPubdataByteLimit,
                    refundRecipient: _dest,
                    secondBridgeAddress: sharedBridge,
                    secondBridgeValue: _amount,
                    secondBridgeCalldata: callData
                }));
        }
    }
}
