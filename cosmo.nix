# mtools via cosmoStaticCross for Windows-x86_64, folded into one .exe with the
# cpp-rename recipe (lib.cppRenameMulticall, isCosmo path): mtools' own argv[0]
# dispatch routes the m* aliases, mkmanifest is the second applet. cosmo rather
# than mingw for iconv and Unicode file names (measured; see the note on
# windowsBuild in flake.nix).

{ unpins-lib, spec, patchedBase }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;
  lib = cosmoPkgs.lib // unpins-lib.lib;
  basePkg = (patchedBase cosmoPkgs.mtools).overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ ./patches/cosmo-undef-privileged.patch ];
  });
in
lib.cppRenameMulticall (spec // {
  pkgs = cosmoPkgs;
  inherit basePkg;
  isCosmo = true;
})
