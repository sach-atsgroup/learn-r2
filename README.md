# radare2 course

A graded, self-contained course in disassembling and debugging with radare2.
Twelve modules, thirteen target binaries, twenty-one graded exercises.

Every target in `src/` was written for this course. Nothing here asks you to touch
software you do not own.

## Setup

```sh
make doctor        # check the toolchain
make               # build every target into build/
```

If `make doctor` says r2 is missing:

```sh
git clone --depth 1 https://github.com/radareorg/radare2 .radare2-src
cd .radare2-src && sudo sys/install.sh && cd ..
```

Later updates: `cd .radare2-src && git pull && sudo sys/install.sh`.
To avoid sudo, use `sys/user.sh` instead and put `~/.local/bin` on your `PATH`.

Validated against **radare2 6.2.5**, commit `ff193bc6018ca2563188f089f7f8df797d869ce6`.
Every command printed in these lessons was checked against that build. If you are on a
different version and something prints nothing, append `?` to the command to get its help.

## How to work through it

1. Read `lessons/NN-*.md`.
2. Solve the exercises against the matching binary in `build/`.
3. Submit each answer:

```sh
make check N=1b A=0x11e9
make score
```

Answers are stored as salted hashes in `answers.sha256`, so reading the repo does not spoil
them. Patching and key-finding exercises are graded by *running* your result, not by hashing.

`solutions/` is empty on purpose. Ask for one module's solution at a time.

## Modules

| # | lesson | target | time | graded |
|---|---|---|---|---|
| 0 | [x86-64, just enough](lessons/00-asm-primer.md) | `00_arith` | 40 min | 0a 0b 0c 0d |
| 1 | [Navigation](lessons/01-navigation.md) | `01_tour` | 60 min | 1a 1b 1c |
| 2 | [Strings, sections, xrefs](lessons/02-strings-xrefs.md) | `02_haystack` | 60 min | 2a 2b 2c |
| 3 | [Static logic reversing](lessons/03-static-reversing.md) · boss | `03_keycheck` | 90 min | 3 |
| 4 | [Dynamic debugging](lessons/04-debugging.md) | `04_guard` | 90 min | 4 |
| 5 | [ESIL emulation](lessons/05-esil.md) | `05_xorbox` | 75 min | 5 |
| 6 | [Types, structs, vtables](lessons/06-types.md) | `06_structs`, `06_vtable` | 60 min | 6a 6b 6c |
| 7 | [Patching](lessons/07-patching.md) | `07_trial` | 75 min | 7 |
| 8 | [Scripting](lessons/08-scripting.md) | `08_many` | 75 min | 8 |
| 9 | [Stripped and optimized](lessons/09-stripped.md) · boss | `09_stripped` | 90 min | 9 |
| 10 | [aarch64 under qemu](lessons/10-aarch64.md) | `10_arm` | 90 min | 10 |
| 11 | [Capstone](lessons/11-capstone.md) · final boss | `capstone` | 2-3 h | 11 |

Total: about 15 hours.

Side files: [cheatsheet.md](cheatsheet.md) (commands by task) and
[pitfalls.md](pitfalls.md) (everything that will waste your time, collected).

## The one habit that matters

Any r2 command takes `?` as a suffix and prints its own help:

```
a?      analysis
af?     analyse function
afl?    list functions
p?      print
d?      debug
```

You will not remember this command set. You do not need to. You need `?`.
