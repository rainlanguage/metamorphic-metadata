pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "../src/SelfDestructMeta.sol";

contract SelfDestructMetaTest is Test {
    // function testPushDestruct0() public {
    //     SelfDestructMeta a = new SelfDestructMeta();
    //     uint256 l0;
    //     assembly ("memory-safe") {
    //         l0 := extcodesize(a)
    //     }
    //     for (uint256 i = 0; i < l0; i++) {
    //         a.poof(i);
    //     }

    //     uint256 l1;
    //     assembly ("memory-safe") {
    //         l1 := extcodesize(a)
    //     }
    //     assertTrue(l1 > 0);
    // }

    // function testPushDestruct1(uint16 i) public {
    //     SelfDestructMeta a = new SelfDestructMeta();
    //     a.poof(i);

    //     uint256 l1;
    //     assembly ("memory-safe") {
    //         l1 := extcodesize(a)
    //     }
    //     assertTrue(l1 > 0);
    // }

    function testPushDestruct2() public {
        SelfDestructMeta a = new SelfDestructMeta();
        a.poof(0x49);
        // a.poof(105);

        uint256 l1;
        assembly ("memory-safe") {
            l1 := extcodesize(a)
        }
        assertTrue(l1 > 0);
    }
}
