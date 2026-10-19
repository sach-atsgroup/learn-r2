# Module 1 — Navigation

**Target:** `build/01_tour` · **Time:** ~60 min · **Graded:** 1a 1b 1c

r2 is a shell over a *seek pointer*. Almost every command acts at the current offset. Learn
to move the seek and you have learned half the tool.

## Open and analyze

```sh
r2 build/01_tour
```

Nothing is analyzed yet. Fix that:

```
[0x00001060]> aaa
```

`a` is analysis. More `a`s mean more work:

| command | what it does | when |
|---|---|---|
| `aa` | functions from symbols and entrypoints | big binaries, first look |
| `aaa` | `aa` + autoname + references + strings | **your default** |
| `aaaa` | `aaa` + experimental extras | when `aaa` missed things |

You can skip typing it: `r2 -A ./bin` runs `aaa` at startup.

## Listing and seeking

```
afl              list functions: address, basic blocks, size, name
afl~main         ... filtered to lines containing "main"
afl~?            ... count the lines instead of printing them
s main           seek to main
s 0x1173         seek to an address
s-               undo the last seek
s+               redo it
?v $$            print the current offset
```

`~` is r2's internal grep, not a shell pipe. It also does more:

```
afl~main         lines matching
afl~?            count lines
afl~[0]          column 0 only
pdf~call         only the lines with "call"
```

## Printing

```
pdf              print disassembly of the current function
pd 20            print 20 instructions from here
pd -5            print the 5 instructions before here
pdf @ main       print main without moving the seek
afi              info about the current function
```

`@` is "temporarily at". `pdf @ main` disassembles main and leaves your seek where it was.
This is the single most useful operator in r2.

## Visual mode

```
V                visual mode; p cycles print modes, q leaves, ? helps
VV               callgraph/ control-flow graph of the current function
```

In `V`: `hjkl` or arrows to move, `Enter` to follow a jump or call, `u` to go back,
`:` to run one normal r2 command, `q` to quit. In `VV`: `HJKL` pans, `+`/`-` zooms.

Spend ten minutes in `VV` on `four_blocks`. Seeing the branch diamond is worth more than
reading fifty lines of `pdf`.

## Configuration

```
e asm.syntax=att      switch to AT&T if you must
e asm.bytes=false     hide the raw bytes column
e asm.lines=false     hide the jump arrows
e~asm.pseudo          search the config for a key
e?                    help
```

Settings live in `~/.radare2rc` if you want them permanently.

### Pitfalls

- **`pdf` prints nothing until you analyze.** No function is known at the seek, so there is
  nothing to print. Run `aaa` (or start with `r2 -A`). This is the single most common
  "r2 is broken" moment.
- **Static functions get a `dbg.` prefix, not `sym.`** when the binary has debug info.
  `01_tour`'s `four_blocks` is `dbg.four_blocks`. Tab completion is your friend; so is
  `afl~four`. Expect `sym.`, `dbg.`, `fcn.` (r2 invented it), `loc.`, `sub.` and `method.`.
- **`aflq` prints addresses only** in 6.x, not names. Reach for `afl` or `aflj` instead.
  Any r2 output format can move between versions — if you are scripting, use the `j` suffix.
- **`afi` field names change between versions.** It is `num-bbs` in 6.2.5, and `afl`'s
  second column is the same number. Grep for what you want rather than assuming a name.
- **`~` is not `|`.** `afl | grep main` leaves r2 and pipes to the shell — which also works,
  but only for text. `afl~main` stays inside r2 and is what scripts should use.
- **PIE binaries are mapped at their file addresses here.** `main` in `01_tour` is at
  `0x11e9` statically. Under the debugger it will be at a different, randomized address.
  That difference is module 4's whole problem.

## Exercises

```sh
r2 -A build/01_tour
```

- **1a** — How many functions does `afl` list? (All of them, imports included.)
- **1b** — What address is `main` at? (Hex or decimal both accepted.)
- **1c** — How many basic blocks does `four_blocks` have?

```sh
make check N=1a A=14
```

## Next

`lessons/02-strings-xrefs.md`.
