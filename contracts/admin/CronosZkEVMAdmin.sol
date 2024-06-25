// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {IAdmin} from "../zksync_contracts_v24/state-transition/chain-interfaces/IAdmin.sol";
import {FeeParams, PubdataPricingMode} from "../zksync_contracts_v24/state-transition/chain-deps/ZkSyncHyperchainStorage.sol";
import {Diamond} from "../zksync_contracts_v24/state-transition/libraries/Diamond.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice CronosZkEVMAdmin
/// Contract account having control of the admin facet. Used to define a more granular role-system than the zkstack
contract CronosZkEVMAdmin is AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant ORACLE = keccak256("ORACLE");
    bytes32 public constant UPGRADER = keccak256("UPGRADER");

    IAdmin adminFacet;

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
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(ORACLE, ADMIN);
        _setRoleAdmin(UPGRADER, ADMIN);
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
        revokeRole(ORACLE, msg.sender);
        revokeRole(UPGRADER, msg.sender);

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
    function changeFeeParams(FeeParams calldata _newFeeParams) external onlyRole(ORACLE) {
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
}