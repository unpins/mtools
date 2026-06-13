{
  description = "mtools (mdir + mcopy + mformat + … + mkmanifest) as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # mtools is ALREADY a native argv[0] multicall: one `mtools` binary that
  # dispatches mattrib/mcopy/mformat/… on its own basename. Upstream ships the
  # m* names as symlinks to it. The ONE separate program is `mkmanifest` (its
  # own main, sharing misc.o/missFuncs.o/patchlevel.o with mtools). We fold
  # mkmanifest into the `mtools` binary with the cpp-rename recipe
  # (lib.cppRenameMulticall): mtools stays primary (its internal dispatch still
  # routes the m* aliases via the preserved argv[0]), mkmanifest becomes a
  # second applet, and the duplicated misc/missFuncs/patchlevel objects are
  # namespaced apart so the two mains can't collide. Upstream's shell helpers
  # (amuFormat.sh, mcheck, mcomp, mxtar, tgz, uz, lz) are dropped — single
  # binary, same policy as gzip's z* scripts.
  outputs = { self, unpins-lib }:
    let
      lib = unpins-lib.lib;
      # signal.c does `#undef got_signal` to neutralise a (dead, commented-out)
      # debug macro in mtools.h — but that also cancels the cpp-rename header's
      # `#define got_signal mtools__got_signal`, so signal.o would define the
      # plain symbol while copyfile/fat/mainloop reference the renamed one
      # (undefined). Drop the `#undef` so the rename applies in signal.c too;
      # got_signal is mtools-only, no cross-program collision.
      patchedBase = drv: drv.overrideAttrs (o: {
        postPatch = (o.postPatch or "") + ''
          substituteInPlace signal.c \
            --replace-fail '#undef got_signal' '/* unpin: keep cpp-rename of got_signal */'
        '';
      });
      # The full mtools object set (Makefile.in OBJS_MTOOLS): @XDF_IO_OBJ@ is
      # always xdf_io.o; @FLOPPYD_IO_OBJ@ is empty (no X11 in a static build).
      mtoolsObjs = [
        "buffer.o" "charsetConv.o" "codepages.o" "config.o" "copyfile.o"
        "device.o" "devices.o" "dirCache.o" "directory.o" "direntry.o"
        "dos2unix.o" "expand.o" "fat.o" "fat_free.o" "file.o" "file_name.o"
        "force_io.o" "hash.o" "init.o" "lba.o" "llong.o" "lockdev.o" "match.o"
        "mainloop.o" "mattrib.o" "mbadblocks.o" "mcat.o" "mcd.o" "mcopy.o"
        "mdel.o" "mdir.o" "mdoctorfat.o" "mdu.o" "mformat.o" "minfo.o" "misc.o"
        "missFuncs.o" "mk_direntry.o" "mlabel.o" "mmd.o" "mmount.o" "mmove.o"
        "mpartition.o" "mshortname.o" "mshowfat.o" "mzip.o" "mtools.o"
        "offset.o" "old_dos.o" "open_image.o" "patchlevel.o" "partition.o"
        "plain_io.o" "precmd.o" "privileges.o" "remap.o" "scsi_io.o" "scsi.o"
        "signal.o" "stream.o" "streamcache.o" "swap.o" "unix2dos.o"
        "unixdir.o" "tty.o" "vfat.o" "strtonum.o" "xdf_io.o"
      ];
      # The m* command names (Makefile.in LINKS) — every one an argv[0] alias
      # of the primary `mtools`, whose internal dispatch reads argv[0].
      mLinks = [
        "mattrib" "mcat" "mcd" "mcopy" "mdel" "mdeltree" "mdir" "mdoctorfat"
        "mdu" "mformat" "minfo" "mlabel" "mmd" "mmount" "mmove" "mpartition"
        "mrd" "mren" "mtype" "mtoolstest" "mshortname" "mshowfat" "mbadblocks"
        "mzip"
      ];
      spec = {
        primary = "mtools";
        # Single top-level Makefile; both programs build in ".".
        makeSubdir = ".";
        # mtools' final link uses $(ALLLIBS); the mk already appends $(LIBS),
        # so passing $(ALLLIBS) here covers MACHDEPLIBS/SHLIB/X_EXTRA_LIBS too.
        linkExtra = "$(ALLLIBS)";
        programs = [
          { name = "mtools"; objs = mtoolsObjs; }
          { name = "mkmanifest"; objs = [ "missFuncs.o" "mkmanifest.o" "misc.o" "patchlevel.o" ]; }
        ];
        aliases = map (n: { name = n; target = "mtools"; }) mLinks;
        extraInstall = ''
          mkdir -p "$out/share/man/man1" "$out/share/man/man5"
          for m in mtools mkmanifest ${builtins.concatStringsSep " " mLinks}; do
            if [ -f "$m.1" ]; then install -m644 "$m.1" "$out/share/man/man1/$m.1"; fi
          done
          if [ -f mtools.5 ]; then install -m644 mtools.5 "$out/share/man/man5/mtools.5"; fi
        '';
      };
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "mtools";
      binName = "mtools";
      # mtools is portable C (FAT image I/O over plain files); macOS builds and
      # runs. charsetConv.c uses iconv — handled centrally by mkStandaloneFlake's
      # withDarwinIconv (the build flows through `stripped`). NOT linuxOnly.
      # Smoke: unlike the other multicalls, mtools' canonical name IS an applet,
      # so argv[0]-based dispatch matters. CI's Windows smoke runs the binary
      # renamed to `smoke.exe`, so argv[0] is neither "mtools" nor an applet, and
      # a bare `--version` would hit the dispatcher's "select a program" error.
      # Select the applet explicitly with --unpin-program (rename-proof, fires
      # before the canonical path on every platform); mtools' own `main` then
      # prints "<name> (GNU mtools) <ver>" and exits 0 before reading any config.
      smoke = [ "--unpin-program=mtools" "--version" ];
      smokePattern = "GNU mtools";
      build = pkgs:
        lib.cppRenameMulticall (spec // {
          inherit pkgs;
          basePkg = patchedBase pkgs.pkgsStatic.mtools;
          isTargetDarwin = pkgs.pkgsStatic.stdenv.hostPlatform.isDarwin;
        });
      # Windows via cosmocc (POSIX layer for file I/O + termios + iconv), same
      # fold. See ./cosmo.nix.
      windowsBuild = import ./cosmo.nix { inherit unpins-lib spec patchedBase; };
    };
}
