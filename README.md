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
unpin mtools --unpin-program=mformat -i disk.img -C -T 65536 ::
unpin mtools --unpin-program=mcopy -i disk.img hello.txt ::/
unpin mtools --unpin-program=mdir -i disk.img ::/
```

To install the programs onto your PATH:

```bash
unpin install mtools
```

`unpin install mtools` creates `mtools`, `mkmanifest` and every `m*` command (`mdir`, `mcopy`, `mformat`, `mdel`, …). `unpin info mtools` lists every command and what it does.

## Man pages

One page per command is embedded — read any with `unpin man mtools <command>`,
e.g. `unpin man mtools mcopy`.

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
- **Windows:** built with [Cosmopolitan](https://github.com/jart/cosmopolitan), not mingw: the mingw build has no iconv, so non-ASCII file names come out mangled (`ação.txt` is extracted as `a__o.txt`).
- **Image files and devices:** on macOS and Windows mtools works on FAT *image files*; Linux also reaches block devices.
- **Configuration:** `-i <image>` needs none. Otherwise mtools reads `/etc/mtools.conf`, `~/.mtoolsrc` or the file `MTOOLSRC` names; on Windows those are `C:\etc\mtools.conf` and `%USERPROFILE%\.mtoolsrc`. The file needs LF line endings: a CRLF line is a syntax error.
- **Not included:** upstream's shell helper scripts (`amuFormat.sh`, `mcheck`, `mxtar`, …; a single binary carries no scripts); the X11 `floppyd` daemon (off in nixpkgs).
- **Tests:** mtools ships no test suite.
