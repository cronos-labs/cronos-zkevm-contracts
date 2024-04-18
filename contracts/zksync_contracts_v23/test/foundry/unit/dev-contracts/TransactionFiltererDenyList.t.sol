// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {BaseTest} from "../_Base_Shared.t.sol";
import {TransactionFiltererDenyList} from "contracts/zksync_contracts_v23/dev-contracts/TransactionFiltererDenyList.sol";

contract TransactionFiltererDenyListTest is BaseTest {
    function test_denylist_returns_false() public {
        address owner = makeAddr("owner");
        address[] memory denylist = new address[](1);
        address s = makeAddr("sender");
        denylist[0] = s;
        TransactionFiltererDenyList td = new TransactionFiltererDenyList(owner, denylist);

        bool allowed = td.isTransactionAllowed(address(s), address(0), 0, 0, "", address(0));
        assertTrue(allowed == false, "contract should denies the tx sender");
    }

    function test_denylist_returns_true() public {
        address owner = makeAddr("owner");
        address[] memory denylist = new address[](1);
        address s = makeAddr("sender");
        address s1 = makeAddr("sender1");
        denylist[0] = s1;
        TransactionFiltererDenyList td = new TransactionFiltererDenyList(owner, denylist);

        bool allowed = td.isTransactionAllowed(address(s), address(0), 0, 0, "", address(0));
        assertTrue(allowed == true, "contract should allows the sender");
    }

    function test_denylist_update_denylist() public {
        address owner = makeAddr("owner");
        address[] memory denylist = new address[](1);
        address s = makeAddr("sender");
        address s1 = makeAddr("sender1");
        denylist[0] = s1;
        TransactionFiltererDenyList td = new TransactionFiltererDenyList(owner, denylist);

        bool allowed = td.isTransactionAllowed(address(s), address(0), 0, 0, "", address(0));
        assertTrue(allowed == true, "contract should allows the sender");

        denylist[0] = s;
        vm.deal(owner, 1 ether);
        vm.prank(address(owner));
        td.updateDenyList(denylist, true);

        allowed = td.isTransactionAllowed(address(s), address(0), 0, 0, "", address(0));
        assertTrue(allowed == false, "contract should denies the tx sender");
    }
}
