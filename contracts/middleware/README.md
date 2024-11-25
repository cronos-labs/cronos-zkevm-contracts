## BridgeMiddleware

This BridgeMiddleware implementation is synchronized from cronos-labs/cronos-zkevm-bridge-middleware.

### Overview
Bridging ETH and ERC20 tokens from L1 (Ethereum) to L2 (Hyperchain) without the need for users to hold the Hyperchain base token.

### How it works:
1. The middleware accepts ETH instead of the Hyperchain base token (zkCRO) to cover L2 transaction costs.
    - With this middleware, the L2 transaction gas fee is still paid in zkCRO, but the middleware swaps the ETH provided by the user to zkCRO behind the scenes, eliminating the need for users to hold zkCRO in their wallets.
2. The middleware needs to be funded with zkCRO.
3. Over time, the funded zkCRO will be consumed and will need to be replenished.
4. Additionally, the middleware will accumulate ETH over time, which can be withdrawn by the `WithdrawAdmin`.
5. The middleware relies on the `baseTokenGasPriceMultipliers` exposed by the Hyperchain to convert between ETH and zkCRO.
