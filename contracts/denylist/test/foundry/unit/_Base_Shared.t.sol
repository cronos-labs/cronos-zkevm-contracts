// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

contract BaseTest is Test {
    // add this to be excluded from coverage report
    function test() internal virtual {}

    address sender;

    function setUp() public virtual {
        sender = makeAddr("sender");
        vm.deal(sender, 100 ether);
    }
}
