import {BaseTest} from "../_Base_Shared.t.sol";
import {BridgeMiddleware} from "../../../../middleware/BridgeMiddleware.sol";
import {TestnetERC20Token} from  "../../../../zksync_contracts_v23/dev-contracts/TestnetERC20Token.sol";

contract TransactionFiltererDenyListTest is BaseTest {
    BridgeMiddleware internal bridgeMiddleware;
    address internal owner;
    TestnetERC20Token erc20;

    function setUp() public override {
        BaseTest.setUp();
        owner = makeAddr("owner");
        vm.startPrank(owner);
        bridgeMiddleware = new BridgeMiddleware();
        bridgeMiddleware.setBridgeParameters(address(1),address(2));
        erc20 = new TestnetERC20Token("TestERC20", "TEST", 18);
    }

    function test_setBridgeParameters_nonOwner_shouldrevert() public {
        vm.startPrank(sender);
        vm.expectRevert();
        bridgeMiddleware.setBridgeParameters(address(0),address(1));
    }

    function test_setBridgeParameters_owner_success() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        bridgeMiddleware.setBridgeParameters(address(0),address(1));
    }

    function test_setCronosZkEVM_nonOwner_shouldrevert() public {
        vm.startPrank(sender);
        vm.expectRevert();
        bridgeMiddleware.setCronosZkEVM(address(0));
    }

    function test_setCronosZkEVM_owner_success() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        bridgeMiddleware.setCronosZkEVM(address(0));
    }

    function test_setChainParameters_nonOwner_shouldrevert() public {
        vm.startPrank(sender);
        vm.expectRevert();
        bridgeMiddleware.setChainParameters(23, 80000);
    }

    function test_setChainParameters_owner_success() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        bridgeMiddleware.setChainParameters(23, 8000);
    }

    function test_approveToken_nonOwner_shouldrevert() public {
        vm.startPrank(sender);
        vm.expectRevert();
        bridgeMiddleware.approveToken(address(erc20), 1000);
    }

    function test_approveToken_owner_success() public {
        vm.deal(owner, 1 ether);
        vm.startPrank(owner);
        bridgeMiddleware.approveToken(address(erc20), 1000);
    }

}