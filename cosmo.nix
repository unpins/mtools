# mtools via cosmoStaticCross for Windows-x86_64, folded into one APE with the
# cpp-rename recipe (lib.cppRenameMulticall, isCosmo path). Same fold as the
# native/darwin builds — mtools' own argv[0] dispatch routes the m* aliases,
# mkmanifest is the second applet. cosmocc supplies the POSIX layer mtools
# needs (file I/O, termios, iconv).
#
# One cosmo-only collision: cosmocc defines a lowercase `privileged` function
# attribute macro (`__section__(".privileged")` + no-instrument), which clashes
# with mtools' `SimpleFile_t.privileged` struct field and locals (config.c,
# plain_io.c, scsi_io.c). Neutralize it at the end of sysincludes.h — the
# common header every affected file includes after the cosmo system headers —
# so mtools' identifier wins. mtools needs no code-section attribute.
{ unpins-lib, spec, patchedBase }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
  lib = cosmoPkgs.lib // unpins-lib.lib;
  basePkg = (patchedBase cosmoPkgs.mtools).overrideAttrs (o: {
    postPatch = (o.postPatch or "") + ''
      cat >> sysincludes.h <<'EOF'
      #ifdef __COSMOPOLITAN__
      #undef privileged   /* cosmo attribute macro vs mtools struct field */
      #endif
      EOF
    '';
  });
in
lib.cppRenameMulticall (spec // {
  pkgs = cosmoPkgs;
  inherit basePkg;
  isCosmo = true;
})
