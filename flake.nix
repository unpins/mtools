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
  # own main, sharing misc.o/missFuncs.o/patchlevel.o with mtools).
  #
  # Every target builds via the unpin-llvm engine + a bitcode multicall module:
  # the standalone self-folds the two real linked programs (`mtools`, with the
  # m* names as argv[0] aliases, and `mkmanifest`) into one binary. The
  # chain-LTO link namespaces the shared objects, and the m* dispatch rides on
  # mtools' own basename handling. Upstream's shell helpers (amuFormat.sh,
  # mcheck, mcomp, mxtar, tgz, uz, lz) are dropped — single binary, same policy
  # as gzip's z* scripts.
  outputs = { self, unpins-lib }:
    let
      lib = unpins-lib.lib;
      # mtools reads SYSCONFDIR/mtools.conf at run time, and with
      # --sysconfdir=$out/etc (the nixpkgs default) that bakes a store path the
      # base does not even create -- so the shipped binary looks for its config
      # in a directory that exists nowhere. /etc is where every distro puts
      # mtools.conf and where a user would look.
      # Nothing is installed there: upstream ships no default config.
      atEtc = drv: drv.overrideAttrs (o: {
        configureFlags = (o.configureFlags or [ ]) ++ [ "--sysconfdir=/etc" ];
      });
      # The X11 floppy daemon isn't built (no X11 in a static build), but its
      # man pages are installed and withMan would embed them.
      noFloppydMan = drv: drv.overrideAttrs (o: {
        postInstall = (o.postInstall or "") + ''
          for out in $outputs; do
            rm -f "''${!out}"/share/man/man1/floppyd*.1*
          done
        '';
      });
      # The m* command names (Makefile.in LINKS) — every one an argv[0] alias
      # of `mtools`, whose internal dispatch reads argv[0].
      mLinks = [
        "mattrib" "mcat" "mcd" "mcopy" "mdel" "mdeltree" "mdir" "mdoctorfat"
        "mdu" "mformat" "minfo" "mlabel" "mmd" "mmount" "mmove" "mpartition"
        "mrd" "mren" "mtype" "mtoolstest" "mshortname" "mshowfat" "mbadblocks"
        "mzip"
      ];
    in
    lib.mkStandaloneFlake {
      inherit self;
      name = "mtools";
      binName = "mtools";
      # mtools is portable C (FAT image I/O over plain files); macOS builds and
      # runs. charsetConv.c's iconv on darwin is resolved by nix-lib. NOT linuxOnly.
      # Smoke: unlike the other multicalls, mtools' canonical name IS an applet,
      # so argv[0]-based dispatch matters. CI's Windows smoke runs the binary
      # renamed to `smoke.exe`, so argv[0] is neither "mtools" nor an applet, and
      # a bare `--version` would hit the dispatcher's "select a program" error.
      # Select the applet explicitly with --unpin-program (rename-proof, fires
      # before the canonical path on every platform); mtools' own `main` then
      # prints "<name> (GNU mtools) <ver>" and exits 0 before reading any config.
      smoke = [ "--unpin-program=mtools" "--version" ];
      smokePattern = "GNU mtools";
      # Engine path: real linked programs are `mtools` (carrying all the
      # m* names as argv[0] aliases — mtools' own main dispatches on basename)
      # and `mkmanifest` (its own main). `mtools` is itself a program, so a bare
      # invocation runs it.
      engine = "unpin-llvm";
      multicall = {
        programs = [
          { name = "mtools"; aliases = mLinks; }
          { name = "mkmanifest"; }
        ];
        windows = true;
      };
      build = pkgs: atEtc (noFloppydMan pkgs.pkgsStatic.mtools);
      # Windows: upstream's mingw recipe, with iconv and a UTF-8 process code
      # page. Without them, Windows 10 extracted `ação.txt` as `a__o.txt` and
      # `日本語.txt` as `___.txt`; the patches say what each fixes.
      windowsBuild = pkgs:
        let mp = lib.mingwStaticCross pkgs; in
        atEtc (noFloppydMan (mp.mtools.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [
            ./patches/mingw-codeset.patch
            ./patches/mingw-utf8-manifest.patch
            ./patches/mingw-ucrt-case.patch
            ./patches/mingw-iconv-eilseq.patch
            ./patches/mingw-home-userprofile.patch
          ];
          buildInputs = (o.buildInputs or [ ]) ++ [ mp.libiconv ];
          makeFlags = (o.makeFlags or [ ]) ++ [ "WINDRES=${mp.stdenv.cc.targetPrefix}windres" ];
        })));
    };
}
