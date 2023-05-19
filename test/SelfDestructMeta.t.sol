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

    function testPushDestruct3() public {
        SelfDestructMeta a = new SelfDestructMeta();
        console.logBytes(address(a).code);

        // a.poof(258);

        for (uint256 i = 0; i < 600; i++) {
            if (
                i == 63 || i == 67 || i == 69 || i == 99 || i == 106 || i == 116 || i == 133 || i == 149 || i == 173
                    || i == 174
            ) {
                continue;
            }

            vm.expectRevert();
            a.poof(i);
        }
        a.poof(63);
        a.poof(67);
        a.poof(69);
        a.poof(106);
        a.poof(116);
        a.poof(133);
        a.poof(149);
        a.poof(173);
        a.poof(174);

        uint256 l1;
        assembly ("memory-safe") {
            l1 := extcodesize(a)
        }
        assertTrue(l1 > 0);
    }
}
