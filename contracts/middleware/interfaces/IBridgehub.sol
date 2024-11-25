// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

struct L2TransactionRequestTwoBridgesOuter {
    /// @notice The hyperchain id
    uint256 chainId;
    /// @notice The hyperchain base token amount for paying the L2 tx fee
    uint256 mintValue;
    /// @notice The L2 tx value, only used when bridging hyperchain base token from L1 to L2
    uint256 l2Value;
    /// @notice The L2 tx gas limit
    uint256 l2GasLimit;
    uint256 l2GasPerPubdataByteLimit;
    address refundRecipient;
    /// The L1SharedBridge address
    address secondBridgeAddress;
    /// If `l1Token == ETH_TOKEN_ADDRESS`, e.g. briging ETH to hyperchain, secondBridgeValue
    ///  is the amount to bridge to L2
    uint256 secondBridgeValue;
    ///  @param l1Token The l1Token address
    ///  @param depositAmount The amount of tokens to deposit/bridge
    ///  @param l2Receiver The l2 address to receive the bridged tokens
    /// (address l1Token, uint256 depositAmount, address l2Receiver) =
    ///      abi.decode(secondBridgeCalldata, (address, uint256, address))
    /// Conditions:
    ///  1. If `l1Token == L1_WETH_TOKEN`, not supported.
    ///  2. If `l1Token == BridgeHub.baseToken(chainId)`, not supported.
    ///     use `BridgeHub.requestL2TransactionDirect` instead.
    ///  3. If `l1Token == ETH_TOKEN_ADDRESS`, e.g. briging ETH to hyperchain
    ///     - `msg.value` is used as the deposit amount
    ///     - `depositAmount` must be 0
    ///  4. If `l1Token` is any other ERC20 token
    ///     - `msg.value` must be 0
    ///     - `depositAmount` must be > 0, and `depsitAmount` of l1Token will be locked in the shared bridge
    bytes secondBridgeCalldata;
}

struct L2TransactionRequestTwoBridgesInner {
    /// bytes32 constant TWO_BRIDGES_MAGIC_VALUE = bytes32(uint256(keccak256("TWO_BRIDGES_MAGIC_VALUE")) - 1);
    bytes32 magicValue;
    /// The L2SharedBridge of the hyperchain. Can get from `L2SharedBridge.l1BridgeAddress(chainId)`
    address l2Contract;
    /// bytes memory gettersData = getERC20Getters(l1Token);
    /// return abi.encodeCall(IL2Bridge.finalizeDeposit, (l1Sender, l2Receiver, l1Token, amount, gettersData));
    bytes l2Calldata;
    bytes[] factoryDeps;
    /// keccak256(abi.encode(_prevMsgSender, _l1Token, amount))
    bytes32 txDataHash;
}

interface IBridgehub {
    event BridgehubDepositFinalized(
        uint256 indexed chainId, bytes32 indexed txDataHash, bytes32 indexed l2DepositTxHash
    );

    function baseToken(uint256 _chainId) external view returns (address);
    function sharedBridge() external view returns (address);
    function getHyperchain(uint256 _chainId) external view returns (address);
    function requestL2TransactionTwoBridges(L2TransactionRequestTwoBridgesOuter calldata _request)
        external
        payable
        returns (bytes32 canonicalTxHash);
    function l2TransactionBaseCost(
        uint256 _chainId,
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);
}
