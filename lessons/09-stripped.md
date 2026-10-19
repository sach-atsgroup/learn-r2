# Module 9 — Stripped and optimized · boss fight

**Target:** `build/09_stripped` · **Time:** ~90 min · **Graded:** 9

```sh
./build/09_stripped SOMEKEY     # exit 1, silently
```

Built `-O2 -s`. No symbols, no debug info, no helpful names, and the source loops are gone.
Find a key it accepts.

Everything up to now had `-O0 -g`. This is what real binaries look like.

## First moves on an unknown binary

```
i                   is it stripped? PIE? what arch?
i~stripped
iS                  sections
ii                  imports: the clearest signal of what it does
iz                  strings
aaa
afl                 what did analysis find
```

Imports are your map. `strlen`, `memcmp`, `fopen`, `puts` each tell you something about the
shape of the logic before you read a single instruction.

## Finding main without symbols

r2's `aaa` usually finds `main` on glibc binaries by reading `entry0`: the entrypoint loads
`main`'s address into `rdi` and calls `__libc_start_main`. If it did not:

```
s entry0
pdf                 look for the lea/mov into rdi before the call
```

Everything reachable from there is your program. Everything else is CRT boilerplate —
`entry.init0`, `entry.fini0`, `deregister_tm_clones` and friends. Learn to recognise and
ignore them.

## Fixing analysis by hand

Auto-analysis guesses. Correct it:

```
af @ 0x1260         analyse a function at this address
af- @ 0x1260        forget it
afu 0x1275          set the current function's end address
afb                 list basic blocks
afn dispatch        name it once you know what it does
aflm                call map: who calls whom
```

When `pdf` shows obvious nonsense after a jump, the function boundary is wrong. `af` at the
right address fixes more than people expect.

## What -O2 does to code

Expect all of these in this binary:

- **A switch becomes arithmetic.** The 12-case switch here is not a jump table. GCC turned
  it into a range check plus a subtraction: `lea edx, [rdi - 0x41]`, `cmp dl, 0xc`,
  `sub eax, 0x40`, and a `cmovae` to zero the out-of-range case. Branchless. Read it as
  `(c >= 'A' && c <= 'M') ? c - 0x40 : 0`.
- **`cmov` instead of a branch.** No jump, no basic-block split — the condition is inside the
  data flow. `cmovae eax, edx` means "if the unsigned compare said above-or-equal, take edx".
- **Loops become SIMD.** The byte-sum loop was auto-vectorized: `punpcklbw`, `punpcklwd`,
  `pshufd`, `paddd` on `xmm` registers, summing four bytes at a time with a scalar tail. The
  source loop does not exist any more. You do not need to trace the SIMD arithmetic —
  recognise the pattern as "sum of the bytes" and move on to the comparison after it.
- **Inlining and cloning.** Small functions vanish into their callers.
- **No frame pointer.** Locals are `rsp`-relative and the offsets shift as the stack moves.

## The gates in this binary

Four, in order. Find each one:

1. an argument-count check,
2. a length check against a constant,
3. a call to a small helper whose result is compared against a constant,
4. a byte comparison at a fixed offset into the string, and a sum compared against a constant.

Satisfy all four. Many keys work; any of them passes.

### Pitfalls

- **Do not assume obfuscation.** Stripped and `-O2` is not obfuscated, it is normal. Reach
  for "the compiler did this" before "someone is hiding something".
- **r2 invents function boundaries confidently and wrongly.** `fcn.00001260` is a real
  function here, but on other binaries you will get functions that start mid-instruction.
  Check that the first instruction of every `fcn.*` looks like a plausible prologue.
- **`s main` fails when there is no `main` symbol.** It is silent. `?v $$` afterwards tells
  you the seek did not move.
- **The `jne` after a `call` tests the callee's return value in `eax`.** With no symbol for
  the callee, that `cmp eax, 7` is your only clue about what the function computes. Work
  backwards from the comparison.
- **`pdc` gets much worse on `-O2`.** SIMD and `cmov` defeat it. Read `pdf`.
- **Strings may be inlined into immediates.** A short string can be loaded as a 64-bit
  constant with no entry in `iz` at all.
- **Do not brute-force by running the binary.** The gates are readable; reading them is the
  exercise. The grader does not care how you got the key, but you will not learn anything
  from a shell loop.

## Exercise

- **9** — A 12-character key that `09_stripped` accepts.

```sh
make check N=9 A='YOUR_KEY'
```

**Badge:** ghost hunter.

## Next

`lessons/10-aarch64.md`.
