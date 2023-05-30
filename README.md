# Metamorphic metadata

Solidity appends CBOR metadata to all contracts that it compiles by default.

The CBOR metadata includes an IPFS hash of the source code used to build the
bytecode and some other metadata.

As I understand the CBOR metadata is a "Solidity thing" NOT an "EVM thing".

I.e. if I were to move the pc into the metadata with a jump and it landed at a
valid jump destination then the EVM, knowing nothing about CBOR metadata, would
happily run the bytes of the metadata as EVM opcodes.

To test this I wrote a script that brute forces IPFS hashes by modifying
**comments** in the source code until it finds an IPFS hash that contains the
2-byte sequence `0x5bff` which is `JUMPDEST SELFDESTRUCT`.

For example, our deployed bytecode might look like:

`0x6080604052348015600f57600080fd5b506004361060285760003560e01c806325d20ef114602d575b600080fd5b60436004803603810190603f9190609b565b6045565b005b605d615bff8291505060598163ffffffff16565b5050565b606360c3565b565b600080fd5b6000819050919050565b607b81606a565b8114608557600080fd5b50565b6000813590506095816074565b92915050565b60006020828403121560ae5760ad6065565b5b600060ba848285016088565b91505092915050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052605160045260246000fdfea2646970667358221220748a4af9208c7ac7d2d439e7ae39963e9d9825504480f252df41db0bb35bff6564736f6c63430008120033`

Where the final bytes are CBOR metadata:

```
a2
64 69706673 5822 1220748a4af9208c7ac7d2d439e7ae39963e9d9825504480f252df41db0bb35bff65
64 736f6c63 43 000812
00 33
```

Encoding reference:

https://docs.soliditylang.org/en/v0.8.19/metadata.html#encoding-of-the-metadata-hash-in-the-bytecode

Note the `0x5bff` near the end of the IPFS hash.

The only thing we need _anywhere_ in our contract to jump to the IPFS hash is

```solidity
function() f;
assembly { f := _pc }
f();
```

Where `_pc` is the byte offset of the jump destination embedded in the IPFS hash.

`_pc` is just a `uint256`, it can come from anywhere, calldata, storage,
hardcoded, etc.

Normally this little snippet can be very powerful and useful. For example, I've
used this to implement an [onchain interpreter](https://github.com/rainprotocol/rain.lib.interpreter).

But it is dangerous if there are any jump destinations that it can reach that you
didn't expect.

## Implications

### Metamorphic backdoors

Metamorphic smart contracts use a combination of `CREATE2` and `SELFDESTRUCT` to
redeploy new bytecode at an existing address.

https://0age.medium.com/the-promise-and-the-peril-of-metamorphic-contracts-9eb8b8413c5e

This can be used to backdoor contracts by making them mutable, such as the
Tornado Cash governance attack.

https://github.com/coinspect/learn-evm-attacks/tree/master/test/Business_Logic/TornadoCash_Governance

There are attempts to automatically scan for metamorphic behaviour but strict
checks for `SELFDESTRUCT` yield false positives, and hueristic based checks have
enough wiggle room to be gamed if an attacker knows how the scanner works.

However, at least the a16z scanner SHOULD detect this particular backdoor
(not tested) because it checks all bytes of the runtime code that follow a jump
destination anywhere in the code.

https://metamorphic.a16zcrypto.com/

https://github.com/a16z/metamorphic-contract-detector/blob/main/metamorphic_detect/opcodes.py#L52

**On the other hand, reading the verified "Contract Source Code" on Etherscan and
looking for self destruct calls in the Solidity source code WILL NOT reveal a
metamorphic backdoor in the metadata. The metamorphic behaviour is ONLY visible
by analysing the raw bytecode directly.**

**This is frustrating because it is just as important, if not more important,
that people can _read_ smart contracts than can write them. If invisible code
can execute that does not appear in the verified source code representation, that
forces code _readers_ at least partially back down to raw bytecode analysis.**

This is somewhat mitigated by the fact that using assembly to dispatch a function
directly is "weird", and so might give someone the clue that they should dig
deeper. An attacker could probably craft some plausible excuse, given the payout
for an attack is multimillion $, if Tornado Cash is a fair example. But at least
the attack isn't completely invisible from the source code, there's a single
"out of band" function call giving it away.

If the attacking contract was assembly heavy "for gas reasons" it would be
relatively easy to slip a function pointer in there somewhere and hope that
nobody notices.

The core issue here is that "people know" that `SELFDESTRUCT` can cause
metamorphic behaviour, but probably don't know that function pointers can reach
jump destinations outside the verified source code that they read on etherscan.
This writeup is raising visibility on that issue.

### Other attacks

Actually, having a jump destination in the IPFS hash allows for a lot of
shenanigans as that's a full 34 bytes for an attacker to work with. For maximum
stealth they can only use a few bytes as they have to brute force a real IPFS
hash, and more bytes = more work, as we know from PoW. 2 bytes for a metamorphic
attack only takes a few minute to an hour to brute force, but more than this will
increase the work exponentially.

If the attacker feels comfortable that the IPFS hash won't actually be checked,
they're free to use the full 34 bytes, or potentially even more of the CBOR
metadata.

The main issue is that what verified source code based viewers like Etherscan
consider "code" is NOT the full executable bytecode, and it's possible to jump
to execution paths outside the logic displayed to the user.

## Mitigation

### Consumers: Use a bytecode level scanner

Scan for metamorphic behaviour at the bytecode level if you want to avoid it.

Simply eyeballing the verified source code for self destruct calls is NOT enough.

You also need to check every suspicious jump and/or every possible jump
destination, including those in bytecode OUTSIDE the visible source code.

### Contract authors/consumers: Don't use/trust CBOR metadata

As I understand, the CBOR metadata isn't even used/checked by Etherscan anyway.

It is presented as-is in a tiny grey box like `ipfs://...` but it's up to you to
download whatever is on the other side of that. Etherscan doesn't even check that
what it displays is a valid IPFS URL with a valid encoded CID.

The same information could be emitted in an event upon constructing a contract,
it doesnt need to be in the literal executable bytecode onchain.

Recent versions of Solidity allow completely eliding the CBOR metadata, their
reasoning is that it isn't deterministic anyway. This is true, I get different
IPFS hashes for this repo when I run it locally on my Mac vs. when I run it on
Github Actions on ubuntu.

### Solidity: Provide an escaped/sanitised CBOR metadata

EVM itself already has a similar issue with the `PUSH` EVM opcodes. It is
possible that push data just coincidentally includes what would otherwise be a
jump destination. Every byte of push data has a program counter, so it would be
possible to jump into a push.

However, EVM DOES NOT allow jumping into push data, this is treated as an invalid
jump destination even if `JUMPDEST` appears inline after a `PUSH`.

Solidity devs _could_ escape/sanitise their CBOR metadata as inline with `PUSH`
ops. A standard 53 byte CBOR metadata could be escaped with just 2 `PUSH` ops.
That would completely negate the ability for anyone to hide anything in the
CBOR metadata.

I reported the above and received this response:

> this does not count as a vulnerability or bug as it's messing with a function
> pointer in inline assembly.

I assume it's unlikely they will sanitise their metadata in the near future.