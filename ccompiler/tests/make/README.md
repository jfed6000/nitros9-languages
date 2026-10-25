# make test harness

Behavioural test cases for the reconstructed OS-9 `make` (there is no baseline
binary to byte-compare against, so `make` can only be validated by running it).

## Test cases

| file       | exercises                                   | expected (`make -n -u <target>`) |
|------------|---------------------------------------------|----------------------------------|
| `makefile` | a single rule (default makefile, target `all`) | prints `echo hello from make` |
| `t_macro`  | `NAME=value` macro + `$(NAME)` expansion     | prints `echo hi there world` |
| `t_dep`    | dependency chain + multiple command lines    | prints the `one`/`two`/`prog` commands |
| `t_cmt`    | `#` and `*` comments, blank lines             | prints `echo after comments` |

The files are stored here with LF endings and tab-indented commands. OS-9 make
wants **CR** line endings, so `os9 copy` them onto the test disk (a binary copy
preserves the tabs; convert LF->CR first, e.g. `tr '\n' '\r'`).

## Deploy + run (usim09pt, picothing L2)

```sh
# make + the makefiles on a test disk, boot with your /dd tools disk:
os9 copy make  boot.dsk,CMDS/make ; os9 attr -e -pe boot.dsk,CMDS/make
tr '\n' '\r' <makefile >mf.os9 ; os9 copy mf.os9 boot.dsk,makefile
usim09pt --input=$'\r\r\rchd /dd\rmake -b -n -u all\r' -d boot.dsk rel_picothing.srec
```

`-n -u` (print commands, unconditional) exercises parse/expand/print without
running commands or touching timestamps — the safest mode for validating logic.

## Current status (2026-10-25)

`make` runs.  The earlier failures in every mode came from nine indexed-indirect
operands that lwasm had assembled with an 8-bit offset, leaving the module 7 bytes
short so every literal call target landed mid-instruction.  With the 16-bit form
forced, the module is 15516 bytes and its call targets hit the real routine
entries.

Results under usim09pt (picothing L2 mega), with `-b` to switch off the built-in
`.c`/`.a` -> `.r` rules:

| test       | `make -b -n -u [-f=<file>]` |
|------------|-----------------------------|
| `makefile` | `echo hello from make` - pass |
| `t_macro`  | `echo hi there world` - pass |
| `t_cmt`    | `echo after comments` - pass |
| `t_dep`    | prints `prog`'s two commands but not those of `one`/`two` |

Without `-b`, a target with no dependencies (`all:`) makes the built-in rules look
for a source file and stop with `can't find source file to make "all.r"`; a target
with a real dependency (`hello: hello.c`) prints `cc -r hello.c` from the built-in
rule followed by its own commands.  Running without `-n` executes the commands.

Whether `t_dep` skipping `one`/`two` is Microware make's semantics for targets with
no dependencies, or a remaining defect, is not settled: there is no reference
binary for this make.  `make_src/` holds the source of a different make (its
compiled module is 15104 bytes and lacks this one's messages), so it cannot serve
as one.
