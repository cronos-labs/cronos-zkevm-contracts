// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {AdminTest} from "../zksync_contracts_v23/state-transition/chain-deps/facets/Admin/_Admin_Shared.t.sol";
import {CronosZkEVMAdmin} from "../../../../admin/CronosZkEVMAdmin.sol";
import {AdminFacet} from  "../../../../zksync_contracts_v24/state-transition/chain-deps/facets/Admin.sol";
import {FeeParams, PubdataPricingMode} from "../../../../zksync_contracts_v24/state-transition/chain-deps/ZkSyncHyperchainStorage.sol";


contract CronosZkEVMAdminTest is AdminTest {
    CronosZkEVMAdmin internal cronosZkEVMAdmin;
    address internal admin;

    function setUp() public override {
        AdminTest.setUp();
        admin = makeAddr("admin");
        cronosZkEVMAdmin = new CronosZkEVMAdmin(address(adminFacet), admin);
        //Make CronosZkEVMAdmin the admin of the admin facet
        address facetAdmin = utilsFacet.util_getAdmin();
        address pendingAdmin = address(cronosZkEVMAdmin);
        vm.startPrank(facetAdmin);
        adminFacet.setPendingAdmin(pendingAdmin);
        assertEq(utilsFacet.util_getPendingAdmin(), pendingAdmin);

        vm.startPrank(pendingAdmin);
        adminFacet.acceptAdmin();
        assertEq(utilsFacet.util_getPendingAdmin(), address(0));
        assertEq(utilsFacet.util_getAdmin(), pendingAdmin);
    }


    function test_transferAdmin_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.transferAdmin(user);
    }

    function test_transferAdmin_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        address user = makeAddr("sender");
        cronosZkEVMAdmin.transferAdmin(address(user));
    }

    function test_setOracle_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.setOracle(user);
    }

    function test_setOracle_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        address user = makeAddr("sender");
        cronosZkEVMAdmin.setOracle(user);
    }

    function test_revokeOracle_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.revokeOracle(user);
    }

    function test_revokeOracle_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        address user = makeAddr("sender");
        cronosZkEVMAdmin.revokeOracle(user);
    }

    function test_setPendingAdmin_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.transferAdmin(user);
    }

    function test_setPendingAdmin_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        address user = makeAddr("sender");
        cronosZkEVMAdmin.setPendingAdmin(user);
    }

    function test_acceptAdmin_nonadmin_shouldrevert() public {
        // Set cronosZkEVMAdmin pending admin first
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setPendingAdmin(address(cronosZkEVMAdmin));

        // Accept admin
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.acceptAdmin();
    }

    function test_acceptAdmin_admin_success() public {
        // Set cronosZkEVMAdmin pending admin first
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setPendingAdmin(address(cronosZkEVMAdmin));

        // Accept admin
        cronosZkEVMAdmin.acceptAdmin();
    }

    function test_changeFeeParamsPendingAdmin_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        FeeParams memory newFeeParams = FeeParams({
            pubdataPricingMode: PubdataPricingMode.Rollup,
            batchOverheadL1Gas: 2_000_000,
            maxPubdataPerBatch: 220_000,
            maxL2GasPerBatch: 100_000_000,
            priorityTxMaxPubdata: 100_000,
            minimalL2GasPrice: 450_000_000
        });
        cronosZkEVMAdmin.changeFeeParams(newFeeParams);
    }

    function test_changeFeeParams_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        FeeParams memory newFeeParams = FeeParams({
            pubdataPricingMode: PubdataPricingMode.Rollup,
            batchOverheadL1Gas: 2_000_000,
            maxPubdataPerBatch: 220_000,
            maxL2GasPerBatch: 100_000_000,
            priorityTxMaxPubdata: 100_000,
            minimalL2GasPrice: 450_000_000
        });
        cronosZkEVMAdmin.changeFeeParams(newFeeParams);
    }

    function test_setTokenMultiplier_nonOracleorAdmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.setTokenMultiplier(1,1);
    }

    function test_setTokenMultiplier_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setTokenMultiplier(1,1);
    }

    function test_setTokenMultiplier_oracle_success() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setOracle(user);
        vm.startPrank(user);
        cronosZkEVMAdmin.setTokenMultiplier(1,1);
    }

    function test_setPubdataPricingMode_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.setPubdataPricingMode(PubdataPricingMode.Validium);
    }

    function test_setPubdataPricingMode_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setPubdataPricingMode(PubdataPricingMode.Validium);
    }

    function test_setTransactionFilterer_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.setTransactionFilterer(address(0));
    }

    function test_setTransactionFilterer_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.setTransactionFilterer(address(0));
    }

    function test_freezeDiamond_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.freezeDiamond();
    }

    function test_freezeDiamond_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.freezeDiamond();
    }

    function test_unfreezeDiamond_nonadmin_shouldrevert() public {
        address user = makeAddr("sender");
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vm.expectRevert();
        cronosZkEVMAdmin.freezeDiamond();
    }

    function test_unfreezeDiamond_admin_success() public {
        vm.deal(admin, 1 ether);
        vm.startPrank(admin);
        cronosZkEVMAdmin.freezeDiamond();
    }

}
