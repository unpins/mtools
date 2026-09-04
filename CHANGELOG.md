# Changelog

## [Unreleased]

Initial release — `mtools` 4.0.49 as a single self-contained binary, built
natively for Linux, macOS, and Windows.

### Added

- Builds for Linux (x86_64, aarch64, armv7l, i686, ppc64le, riscv64), macOS
  (x86_64, aarch64), and Windows.
- Every `m*` command plus `mkmanifest` in the one binary — `unpin install
  mtools` creates all 26 as commands.
- One man page per command embedded in the binary — read any with
  `unpin man mtools <command>`, e.g. `unpin man mtools mcopy`.
- The config file is read from `/etc/mtools.conf`, where distributions put it;
  `MTOOLSRC` overrides it as usual. Nothing is installed there — upstream ships
  no default config.

### Removed

- Upstream's shell helper scripts (`amuFormat.sh`, `mcheck`, `mcomp`, `mxtar`,
  `tgz`, `uz`, `lz`) — this is a single binary, not a directory of scripts.
- The X11 `floppyd` daemon and its man page: it needs X11, which a
  self-contained binary does not link.
