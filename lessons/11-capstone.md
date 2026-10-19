# Module 11 — Capstone · final boss

**Target:** `build/capstone` · **Time:** 2–3 h · **Graded:** 11

```sh
./build/capstone SOMETHING
# STAGE 1 FAILED
```

Goal: make it print `WAVE CAPSTONE CLEARED`.

No hints, no walkthrough, no command list. Everything you need is in modules 1 through 10.

## Rules

1. The program takes exactly one argument.
2. Stage 1 checks that argument. Find the right one.
3. Stage 2 checks something that is **not true on this machine and cannot be made true by
   supplying a different argument**. Deal with it.
4. The patched binary must live at `build/capstone.patched` and must differ from the
   original.

```sh
cp build/capstone build/capstone.patched
```

## Grading

```sh
make check N=11 A='the_argument'
```

The grader runs `build/capstone.patched` with your argument and requires exit 0 and
`WAVE CAPSTONE CLEARED` on stdout. It also refuses a copy that is byte-identical to the
original, so you cannot pass stage 2 by accident.

## If you are stuck

In this order:

1. `i` and `ii`. What does it import? One of the imports tells you exactly what stage 2 does.
2. `afl`. Which functions are not CRT boilerplate?
3. Read `main`. Both stages are visible in it.
4. Stage 1's comparison buffer is not what it looks like at rest. Something runs before the
   comparison. Module 5.
5. Stage 2 is module 7.

**Badge:** WAVE capstone.

## After this

You can read `pitfalls.md` as a reference now rather than a warning list, and `cheatsheet.md`
is the thing to keep open. The natural next steps from here:

- Run `r2 -A` over a real binary from the WAVE repos and see how much of it reads cleanly.
- `r2pm -ci r2ghidra` and compare `pdg` to your own reading on module 9.
- Point `scripts/inventory.py` at a directory of firmware builds and diff two versions.
