//
pragma solidity ^0.8.18;

contract SelfDestructMeta {
    /// Comments seem harmless but they change the meta hash.
    function poof(uint256 _pc) external {
        function() f;
        assembly ("memory-safe") {
            let x := 0x5BFF
            f := _pc
        }
        f();
    }
}