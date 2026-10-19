# Module 7 — Patching

**Target:** `build/07_trial` · **Time:** ~75 min · **Graded:** 7

```sh
./build/07_trial        # TRIAL EXPIRED, exit 1
```

Make it print `WAVE UNLOCKED` and exit 0, by editing the bytes — not the source.

Patching is the skill behind field debugging: flipping a check in a binary you cannot
rebuild, neutralizing a call, or redirecting a branch to test a hypothesis in seconds.

## Work on a copy

```sh
cp build/07_trial build/07_trial.patched
```

The grader checks `build/07_trial.patched` and refuses an unmodified copy. `make` would
overwrite the original anyway. **Always patch a copy.** This is not pedantry; r2's write
mode edits in place with no undo.

## Opening for writing

```sh
r2 -w build/07_trial.patched
```

Or from inside a read-only session:

```
oo+            reopen the current file in read-write mode
```

Check which mode you are in with `o` — a `rw` in the perm column means writes will land.

## Writing

```
wx 9090                 write raw hex bytes here
wa jmp 0x117f           assemble one instruction and write it here
wa nop                  ... a nop
wao nop                 replace the current instruction with nops, correctly sized
wao nocj                turn the current conditional jump into nothing
wao recj                reverse the current conditional jump's condition
w hello                 write a string
wz hello                ... zero-terminated
wc                      list pending changes when io.cache is on
wc-*                    discard them
```

`wao` is the safe family: it knows the current instruction's length and pads for you.
`wa` does not.

## The route for this target

```
aaa
pdf @ main
```

You will find `test eax, eax` followed by a conditional jump that skips the success path.
Three ways to fix it, all valid:

1. Turn the conditional jump into an unconditional one — `wa jmp <success addr>`.
2. Reverse the condition — `wao recj`.
3. Patch `days_left` to return a positive number — `s dbg.days_left` then `wa mov eax, 1`
   followed by `wa ret`.

Do all three, on three copies. Then check your work:

```
pd 1            confirm the instruction now reads what you meant
```

```sh
./build/07_trial.patched; echo "exit=$?"
```

### Pitfalls

- **`wa` can change the instruction length and silently corrupt the next one.** `jg` with a
  short displacement is 2 bytes; the `jmp` you replace it with may assemble to 2 or 5
  depending on the target. If it is longer, it eats the following instruction. Always `pd 2`
  after writing and look at what comes next. If it is shorter, pad with `wa nop` — or avoid
  the problem entirely and use `wao`.
- **Writes go nowhere without write mode.** `wx` in a read-only session reports success and
  changes nothing on disk. Open with `-w`, or `oo+`.
- **Check your seek before every write.** `wx` writes at the current offset. A stray `s` or
  a `pdf @ somewhere` that you thought moved the seek (it does not) means you overwrite the
  wrong bytes. `?v $$` costs nothing.
- **Patching a `call` away breaks the stack if the callee returned something you use.**
  `wao nop` over a `call` leaves `rax` holding whatever was there before. Patch the *test*
  after the call, not the call itself, unless you know the return value is unused.
- **The checksum / signature problem does not exist here, but it will elsewhere.** Many real
  binaries verify themselves. Patching the check is then a second, separate job.
- **PIE does not matter for file patching.** You are editing file bytes at their mapped
  addresses; r2 handles the translation. It matters for *debugging*, not writing.

## Exercise

- **7** — `build/07_trial.patched` exists, differs from the original, exits 0 and prints
  `WAVE UNLOCKED`.

```sh
make check N=7
```

## Next

`lessons/08-scripting.md`.
