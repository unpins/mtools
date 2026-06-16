# mtools

[mtools](https://www.gnu.org/software/mtools/) — read, write and manipulate MS-DOS / FAT filesystems (and disk images) without mounting them: `mdir`, `mcopy`, `mformat`, `mlabel`, `mtype`, `mmd`, … plus `mkmanifest`. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/mtools/actions/workflows/mtools.yml/badge.svg)](https://github.com/unpins/mtools/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install mtools`.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin mtools mformat -i disk.img -C -T 65536 ::
unpin mtools mcopy -i disk.img hello.txt ::/
unpin mtools mdir -i disk.img ::/
```

To install the programs onto your PATH:

```bash
unpin install mtools
```

`unpin install mtools` creates `mtools`, `mkmanifest` and every `m*` command (`mattrib`, `mcat`, `mcd`, `mcopy`, `mdel`, `mdeltree`, `mdir`, `mdoctorfat`, `mdu`, `mformat`, `minfo`, `mlabel`, `mmd`, `mmount`, `mmove`, `mpartition`, `mrd`, `mren`, `mtype`, `mtoolstest`, `mshortname`, `mshowfat`, `mbadblocks`, `mzip`). `unpin info mtools` lists every command and what it does.

## Build locally

```bash
nix build github:unpins/mtools
./result/bin/mtools --version
```

Or run directly:

```bash
nix run github:unpins/mtools -- --version
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/mtools/releases) page has standalone binaries for manual download.

## Build notes

- **Platforms:** Linux (x86_64, i686, ppc64le, riscv64, aarch64, armv7l), macOS (x86_64, aarch64), Windows (x86_64).
- **Multicall:** mtools is already a single `argv[0]`-dispatch binary for the `m*` commands. The one separate program, `mkmanifest`, is folded into the same binary via a source-level `main` → `<prog>_main` rename (`lib.cppRenameMulticall`); the `m*` names dispatch through mtools' own internal table. Upstream's shell helper scripts (`amuFormat.sh`, `mcheck`, `mxtar`, …) are dropped under the single-binary policy.
- **macOS / Windows:** mtools operates on FAT *image files* (and, on Linux, block devices). `charsetConv.c`'s `iconv` use is linked statically on macOS. The Windows build uses [Cosmopolitan](https://github.com/jart/cosmopolitan), with cosmo's lowercase `privileged` attribute macro neutralized where it collides with mtools' `SimpleFile_t.privileged` field — see [`cosmo.nix`](cosmo.nix).
- **Man pages:** the per-command pages are embedded; read with `unpin man mtools mcopy`.
