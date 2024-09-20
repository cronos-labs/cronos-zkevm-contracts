// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IAdmin} from "../zksync_contracts_v24/state-transition/chain-interfaces/IAdmin.sol";
import {FeeParams, PubdataPricingMode} from "../zksync_contracts_v24/state-transition/chain-deps/ZkSyncHyperchainStorage.sol";
import {Diamond} from "../zksync_contracts_v24/state-transition/libraries/Diamond.sol";
import {ValidatorTimelock} from "../zksync_contracts_v24/state-transition/ValidatorTimelock.sol";
import {IChainAdmin} from "./IChainAdmin.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";


/// @notice CronosZkEVMAdmin
/// Contract account having control of the admin facet. Used to define a more granular role-system than the zkstack
contract CronosZkEVMAdmin is AccessControl, IChainAdmin {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public constant UPGRADER = keccak256("UPGRADER");
    bytes32 public constant FEE_ADMIN = keccak256("FEE_ADMIN");

    IAdmin adminFacet;

    /// @notice Mapping of protocol versions to their expected upgrade timestamps.
    /// @dev Needed for the offchain node administration to know when to start building batches with the new protocol version.
    mapping(uint256 protocolVersion => uint256 upgradeTimestamp) public protocolVersionToUpgradeTimestamp;

    constructor(address _adminFacet, address _admin){
        adminFacet = IAdmin(_adminFacet);

        address admin = _admin;
        if (admin == address(0)) {
            admin = msg.sender;
        }
        // ACL
        _grantRole(ADMIN, admin);
        _grantRole(ORACLE, admin);
        _grantRole(UPGRADER, admin);
        _grantRole(FEE_ADMIN, admin);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(ORACLE, ADMIN);
        _setRoleAdmin(UPGRADER, ADMIN);
        _setRoleAdmin(FEE_ADMIN, ADMIN);
    }

    /*//////////////////////////////////////////////////////////////
                        ACL
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer admin role to a new address
    function transferAdmin (
        address _newAdmin
    ) public onlyRole(ADMIN) {
        grantRole(ADMIN, _newAdmin);
        grantRole(ORACLE, _newAdmin);
        grantRole(UPGRADER, _newAdmin);
        grantRole(FEE_ADMIN, _newAdmin);
        revokeRole(ORACLE, msg.sender);
        revokeRole(UPGRADER, msg.sender);
        revokeRole(FEE_ADMIN, msg.sender);

        //revoke admin role last
        revokeRole(ADMIN, msg.sender);
    }

    /// @notice Set oracle role
    function setOracle (
        address _oracle
    ) public onlyRole(ADMIN) {
        grantRole(ORACLE, _oracle);
    }

    /// @notice Revoke oracle role
    function revokeOracle (
        address _oracle
    ) public onlyRole(ADMIN) {
        revokeRole(ORACLE, _oracle);
    }

    /// @notice Set upgrader role
    function setUpgrader (
        address _upgrader
    ) public onlyRole(ADMIN) {
        grantRole(UPGRADER, _upgrader);
    }

    /// @notice Revoke upgrader role
    function revokeUpgrader (
        address _upgrader
    ) public onlyRole(ADMIN) {
        revokeRole(UPGRADER, _upgrader);
    }

    /// @notice Set fee_admin role
    function setFeeAdmin (
        address _feeAdmin
    ) public onlyRole(ADMIN) {
        grantRole(FEE_ADMIN, _feeAdmin);
    }

    /// @notice Revoke fee_admin role
    function revokeFeeAdmin (
        address _feeAdmin
    ) public onlyRole(ADMIN) {
        revokeRole(FEE_ADMIN, _feeAdmin);
    }


    /*//////////////////////////////////////////////////////////////
                        ADMIN FACET EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Call admin facet setPendingAdmin
    function setPendingAdmin(address _newPendingAdmin) external onlyRole(ADMIN) {
        adminFacet.setPendingAdmin(_newPendingAdmin);
    }

    /// @notice Call admin facet acceptAdmin
    function acceptAdmin() external onlyRole(ADMIN) {
        adminFacet.acceptAdmin();
    }

    /// @notice Call admin facet changeFeeParams
    function changeFeeParams(FeeParams calldata _newFeeParams) external onlyRole(FEE_ADMIN) {
        adminFacet.changeFeeParams(_newFeeParams);
    }

    /// @notice Call admin facet setTokenMultiplier
    function setTokenMultiplier(uint128 _nominator, uint128 _denominator) external onlyRole(ORACLE) {
        adminFacet.setTokenMultiplier(_nominator,_denominator);
    }

    /// @notice Call admin facet setPubdataPricingMode
    function setPubdataPricingMode(PubdataPricingMode _pricingMode) external onlyRole(ADMIN) {
        adminFacet.setPubdataPricingMode(_pricingMode);
    }

    /// @notice Call admin facet setTransactionFilterer
    function setTransactionFilterer(address _transactionFilterer) external onlyRole(ADMIN) {
        adminFacet.setTransactionFilterer(_transactionFilterer);
    }

    /// @notice Call admin facet upgradeChainFromVersion
    function upgradeChainFromVersion(
        uint256 _oldProtocolVersion,
        Diamond.DiamondCutData calldata _diamondCut
    ) external onlyRole(UPGRADER) {
        adminFacet.upgradeChainFromVersion(_oldProtocolVersion, _diamondCut);
    }

    /// @notice Call admin facet freezeDiamond
    function freezeDiamond() external onlyRole(ADMIN) {
        adminFacet.freezeDiamond();
    }

    /// @notice Call admin facet unfreezeDiamond
    function unfreezeDiamond() external onlyRole(ADMIN) {
        adminFacet.unfreezeDiamond();
    }

    /*//////////////////////////////////////////////////////////////
                    TIMELOCK EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets an address as a validator.
    function addValidator(address _timelockAddress, uint256 _chainId, address _newValidator) external onlyRole(ADMIN) {
        ValidatorTimelock(_timelockAddress).addValidator(_chainId, _newValidator);
    }

    /// @dev Removes an address as a validator.
    function removeValidator(address _timelockAddress, uint256 _chainId, address _validator) external onlyRole(ADMIN) {
        ValidatorTimelock(_timelockAddress).removeValidator(_chainId, _validator);
    }

    /*//////////////////////////////////////////////////////////////
                    CHAIN ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the expected upgrade timestamp for a specific protocol version.
    /// @param _protocolVersion The ZKsync chain protocol version.
    /// @param _upgradeTimestamp The timestamp at which the chain node should expect the upgrade to happen.
    function setUpgradeTimestamp(uint256 _protocolVersion, uint256 _upgradeTimestamp) external onlyRole(UPGRADER) {
        protocolVersionToUpgradeTimestamp[_protocolVersion] = _upgradeTimestamp;
        emit UpdateUpgradeTimestamp(_protocolVersion, _upgradeTimestamp);
    }

    /// @notice Execute multiple calls as part of contract administration.
    /// @param _calls Array of Call structures defining target, value, and data for each call.
    /// @param _requireSuccess If true, reverts transaction on any call failure.
    /// @dev Intended for batch processing of contract interactions, managing gas efficiency and atomicity of operations.
    function multicall(Call[] calldata _calls, bool _requireSuccess) external payable onlyRole(ADMIN) {
        require(_calls.length > 0, "No calls provided");
        for (uint256 i = 0; i < _calls.length; ++i) {
            // slither-disable-next-line arbitrary-send-eth
            (bool success, bytes memory returnData) = _calls[i].target.call{value: _calls[i].value}(_calls[i].data);
            if (_requireSuccess && !success) {
                // Propagate an error if the call fails.
                assembly {
                    revert(add(returnData, 0x20), mload(returnData))
                }
            }
            emit CallExecuted(_calls[i], success, returnData);
        }
    }

}