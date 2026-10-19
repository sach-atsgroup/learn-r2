# Module 2 — Strings, sections, cross-references

**Target:** `build/02_haystack` · **Time:** ~60 min · **Graded:** 2a 2b 2c

Strings are the fastest way into an unknown binary. The skill is not finding strings — it is
finding the *one* string that the code actually uses.

`02_haystack` contains 192 decoy strings, one real one, and one hidden past the end of the
last section.

## Binary information

The `i` family. All of it is static; nothing runs.

```
i            headers: format, arch, bits, PIE, stripped, canary, NX
iz           strings in the data sections
izz          strings in the whole file
is           symbols
ii           imports
ie           entrypoints
iS           sections
iI           binary info in detail
il           linked libraries
```

Each takes `q` for quiet and `j` for JSON: `izq`, `izj`.

Start every unfamiliar binary with `i`. "Is it stripped? Is it PIE? What arch?" changes
everything you do next.

## Cross-references

A string is interesting when code refers to it.

```
axt            what references the current address ("xrefs TO")
axf            what the current address references ("xrefs FROM")
axt @ 0x2cf1   ... without moving the seek
```

`axt` is how you get from "there is a string that says FAILED" to "here is the function that
prints it", which is almost always where the logic you want lives.

## The workflow

```sh
r2 -A build/02_haystack
```

```
iz~?              how many strings in data sections
izz~?             how many in the whole file
iz~needle         find a specific one
axt @ <addr>      who refers to it
s <function>      go to the caller
pdf               read it
```

### Pitfalls

- **`iz` and `izz` give different answers, and both are right.** `iz` scans only sections
  flagged as data. `izz` scans every byte of the file, including things that are not
  really strings and things outside any section. In this target `iz` finds 193 and `izz`
  finds 302. If a string you *know* is in the file does not show up in `iz`, try `izz`
  before concluding anything. Exercise 2c is exactly this case: a string appended past the
  last section, invisible to `iz`.
- **No xref does not mean unused.** It can also mean r2's analysis missed it — computed
  addresses, jump tables and `-O2` code defeat it regularly. Treat "no xrefs" as a hint.
- **The decoys here have no individual xrefs** because they live inside one blob. Real
  binaries do this too, with string tables. The absence of an xref to a *string* may just
  mean the xref points at the table it lives in.
- **`is` on a stripped binary returns almost nothing.** That is information, not failure.
  Check `i~stripped` first so you know which world you are in.
- **Addresses from `iz` are file-relative for non-PIE and vaddr for PIE.** `iz` prints both
  (`paddr` and `vaddr` in the JSON). Use the vaddr with `axt`.

## Exercises

- **2a** — There is exactly one string in this binary referenced from code. What is it,
  in full?
- **2b** — Which function references it? (Give the name without any r2 prefix.)
- **2c** — One string in the file is invisible to `iz` but visible to `izz`. What is it,
  in full?

```sh
make check N=2b A=gate
```

## Next

`lessons/03-static-reversing.md` — the first boss fight.
