# Module 8 — Scripting and automation

**Target:** `build/08_many` · **Time:** ~75 min · **Graded:** 8

`08_many` has 60 functions named `op_<subsystem>_<verb>`. Counting them by hand is the
wrong answer. This is the module that makes r2 useful at work: triaging a whole directory
of firmware builds instead of clicking through one.

## One-liners

```sh
r2 -q -c 'aaa; afl' build/08_many          # run commands, quit
r2 -qc 'aaa; afl~?' build/08_many          # -q and -c can be joined
r2 -A -q -c 'afl' build/08_many            # -A is "run aaa at startup"
r2 -q -i script.r2 build/08_many           # run a file of commands
r2 -q -e scr.color=0 -c 'pdf @ main' bin   # no ANSI codes, for piping
```

Chain commands with `;`. Put them in a `.r2` file, one per line, for anything longer.

## JSON, and why text output is a trap

Every listing command takes a `j` suffix:

```sh
r2 -qc 'aaa; aflj' build/08_many | jq -r '.[] | "\(.name) \(.size)"'
r2 -qc 'aaa; aflj' build/08_many | jq '[.[] | select(.name | test("op_"))] | length'
r2 -qc 'izj' build/02_haystack | jq -r '.[].string'
r2 -qc 'aaa; pdfj @ main' build/08_many | jq -r '.ops[] | "\(.offset) \(.disasm)"'
```

Use JSON. Text output columns move between r2 versions — `aflq` printing names in one
release and bare addresses in the next is exactly the kind of breakage that silently
returns zero results.

## r2pipe

For anything with logic in it, drive r2 from Python:

```python
import r2pipe
r2 = r2pipe.open("build/08_many")
r2.cmd("aaa")
funcs = r2.cmdj("aflj")          # cmdj parses the JSON for you
for f in funcs:
    print(f["name"], hex(f["addr"]), f["size"])
r2.quit()
```

`cmd` returns text, `cmdj` returns parsed JSON. Run it without installing anything globally:

```sh
uv run --with r2pipe python3 scripts/inventory.py build/08_many
```

### Pitfalls

- **Forgetting `aaa` in a script** gives you an empty list and no error. Every script that
  looks at functions must analyze first, or open with `r2 -A`.
- **`aflq` prints addresses only** in 6.x. Any script that parsed names out of it is broken.
  This is the general lesson: parse JSON, not columns.
- **ANSI colour codes poison piped text output.** Pass `-e scr.color=0` whenever you pipe
  `cmd` output anywhere. `cmdj` is unaffected.
- **`aaa` is slow on big binaries.** On a large firmware image it can take minutes. Use `aa`
  when you only need symbol-derived functions, and measure before you parallelize.
- **r2pipe leaves processes behind** if you never call `quit()`. Use it in a `try/finally`,
  or `with r2pipe.open(...)` where supported.
- **`aflj` calls the address `addr`, not `offset`.** And it is `nbbs` there while `afi`
  calls the same number `num-bbs`. Dump the keys once (`aflj | jq '.[0]|keys'`) rather than
  guessing; a wrong key is a `KeyError`, which is at least loud.
- **r2pipe prints its INFO banner to the same place as your output** unless you redirect
  stderr. Keep stdout for JSON only.
- **The function name includes r2's prefix.** `dbg.op_io_init`, not `op_io_init`. Strip it,
  or match on a substring.
- **`cmdj` returns `None` on a command that produced no JSON**, including when the command
  name was wrong. Check for `None` before iterating, or a typo looks like an empty binary.

## Exercise

Write `scripts/inventory.py`. It takes a binary path as `argv[1]`, analyzes it, and prints a
**JSON list** to stdout, one object per function, each with at least:

```json
[{"name": "dbg.op_io_init", "addr": 4472, "size": 27}]
```

The grader requires: valid JSON, a top-level list, exactly 60 entries whose name contains
`op_`, each with `name`, `addr` and `size`, `size` a positive integer, and the functions
`op_io_init`, `op_spraying_clear`, `op_battery_selftest`, `op_driving_poll` and
`op_plungers_arm` present.

It is run as:

```sh
uv run --quiet --with r2pipe python3 scripts/inventory.py build/08_many
```

- **8** — `scripts/inventory.py` produces that output.

```sh
make check N=8
```

## Next

`lessons/09-stripped.md` — the second boss fight.
