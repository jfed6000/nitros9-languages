# Canonical binary baseline

The files in this directory are the **canonical reference binaries** for the
Microware OS-9 C compiler, extracted verbatim from the original distribution
disk:

    nitros9/3rdparty/packages/ccompiler/os9c1.dsk,CMDS

They are the source of truth for the byte-identical reconstruction in this
directory's `*.asm` sources. A build is correct when it reassembles to these
exact bytes. Integrity is recorded in `SHA256SUMS`.

## Validating a build

```sh
make cc1 c.prep c.pass1 c.pass2 c.opt c.asm c.link
for m in c.pass1 c.pass2 c.opt c.asm c.link; do cmp "$m" "baseline/$m"; done
shasum -a 256 -c baseline/SHA256SUMS   # (from this directory, against baseline copies)
```

## Coverage and known intentional deltas

| module   | reproduces baseline? | notes |
|----------|----------------------|-------|
| c.pass1  | yes, byte-identical  | |
| c.pass2  | yes, byte-identical  | |
| c.opt    | yes, byte-identical  | |
| c.asm    | yes, byte-identical  | built from `c_asm.asm`, then copied |
| c.link   | yes, byte-identical  | |
| cc1      | **intentional delta** | default library device changed `/d1` (baseline) -> `/dd`; 1 byte at file offset 0x0EE6 + module CRC. Otherwise identical. |
| c.prep   | **intentional delta** | same `/d1` -> `/dd` change; 1 byte at 0x135D + CRC. |
| c.comp   | no baseline           | single-pass front end; not present on os9c1.dsk (the package ships the two-pass pipeline only). |
| cc2      | no baseline           | `cc1.asm -DCC2=1` driver variant; invokes c.comp instead of c.pass1/c.pass2. |
| make     | no baseline           | build tool, not part of os9c1.dsk. |

## History

Baselining against os9c1.dsk exposed a reconstruction defect: lwasm assembled
`[symbol,y]` indexed-**indirect** operands with an 8-bit offset (`?B8 nn`) where
the original assembler always used the 16-bit form (`?B9 00 nn`). Each occurrence
made a module one byte short, shifting every downstream address reference and
corrupting the module's internal jump tables -> the compiler crashed mid-compile.
Fixed by forcing the 16-bit offset with `[>symbol,y]`:

- c.pass2.asm: 1 site
- c.pass1.asm: 5 sites
- c.comp.asm:  5 sites (no baseline to diff; found by the same 8-bit-indirect scan)

After the fix, c.pass1/c.pass2 reproduce os9c1.dsk exactly and c.comp compiles
correctly instead of crashing.
