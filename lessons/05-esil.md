# Module 5 — ESIL emulation

**Target:** `build/05_xorbox` · **Time:** ~75 min · **Graded:** 5

```sh
./build/05_xorbox GUESS     # BOX SHUT
```

The secret is a 16-byte buffer, XOR-encoded in `.data`, decoded at startup by `decode()`, and
compared with your argument. It is never printed.

You could debug it. You could also decode it by hand. Instead, make r2 run the decode loop
*inside itself* — no process, no ptrace, no risk. That is ESIL.

ESIL is r2's intermediate language: every instruction is lifted to a little stack-machine
expression that r2 can evaluate. You get a virtual CPU you can step, inspect and rewind,
which is exactly right for "run this one loop and show me the result".

## Setting up the VM

```
aei            initialise the ESIL VM
aeim           initialise ESIL memory (a stack)
aeip           set the ESIL program counter to the current seek
aer            show ESIL registers
aer rax=1      set one
aeim-          tear the memory down again
```

Order matters: `aei`, then `aeim`, then `aeip`.

## Running

```
aes            step one instruction
aes 10         step ten
aeso           step over a call
aesu <addr>    step until an address
aecu <addr>    continue until an address
aesB <addr>    step until a breakpoint-ish condition
```

`aesu` is the workhorse: "emulate from here until we reach there".

## Reading the result

ESIL writes go into r2's IO layer. Enable the write cache first or you will read the
original file bytes back and wonder why nothing happened:

```
e io.cache=true
```

Then, after emulating, read normally:

```
px 16 @ <addr>
psz @ <addr>
```

To throw the emulated writes away: `wc-*` drops the cache.

## The recipe for this target

```sh
r2 -A build/05_xorbox
```

```
e io.cache=true
afl~decode              find the function
s <decode>              seek to it
pdf                     read it: find the loop and the return
aei
aeim
aeip
aesu <address of the ret>
is~box                  where the buffer lives
psz @ <box vaddr>
```

That prints the plaintext without the program ever running.

### Pitfalls

- **`e io.cache=true` is mandatory.** Without it, `aesu` runs happily and `psz` shows you the
  *encoded* bytes, because the writes went to a cache that the read path is ignoring. This
  silently produces a wrong answer rather than an error, which makes it the worst pitfall in
  the course. If your output looks like garbage, check this first.
- **`aei` without `aeim` gives a VM with no stack.** Anything that pushes, pops, calls or
  touches a local faults in confusing ways. Always pair them.
- **ESIL does not emulate syscalls.** `read`, `write`, `open` and friends do nothing useful.
  Emulate the *computation*, not the program. Never try to `aesu` through `main`.
- **ESIL does not emulate library calls either.** Stepping into `memcmp` from the PLT goes
  nowhere good. `aeso` over calls you do not care about.
- **The ESIL PC is separate from your seek.** `aeip` syncs it to the seek once. After that,
  moving the seek with `s` does not move the emulated PC. Check with `aer rip`.
- **Pick the right stop address.** `aesu` at the function's last instruction stops *before*
  executing it. For a `ret` that is fine. For the last instruction of a loop body it is not.
- **Vectorized and FPU instructions are incompletely lifted.** If emulation produces nonsense
  on `-O2` code, check whether the loop became SSE (module 9 has one of those). ESIL is best
  on straightforward integer code.

## Exercise

- **5** — The 16-character secret that `05_xorbox` accepts.

```sh
make check N=5 A='THE_SECRET'
```

## Next

`lessons/06-types.md`.
