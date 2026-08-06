{ pkgs ? import <nixpkgs> {} }:

let

  mountingScriptsPackage = (import ./default.nix { inherit pkgs; }).mountingScripts;

  adbPackage = pkgs.android-tools;

  gzipPackage = pkgs.gzip; # provides zcat, used by kernel/pull_defconfig.sh

  # like the Makefile's mobile-install target, but builds the release tarball
  # via nix-build (mountingScripts) instead of a local `make release`
  mobileInstallPackage = pkgs.writeShellScriptBin "pbg-mobile-install" ''
    set -e
    out=$(${pkgs.nix}/bin/nix-build --no-out-link -A mountingScripts ${./default.nix})
    tarball="$out/share/pixel-backup-gang.tar.gz"

    ${adbPackage}/bin/adb push "$tarball" /data/local/tmp
    ${adbPackage}/bin/adb shell su --command \
      "tar -xvf /data/local/tmp/$(basename "$tarball") -C /data/local/tmp"
    ${adbPackage}/bin/adb shell su --command \
      "chmod +x /data/local/tmp/pixel-backup-gang/*.sh"
  '';

  allInputs =
    (mountingScriptsPackage.buildInputs or [])
    ++ (mountingScriptsPackage.nativeBuildInputs or [])
    ++ [ adbPackage gzipPackage mobileInstallPackage ];

  inputPackageNames = "\n  - " + builtins.concatStringsSep "\n  - "
    (map (pkg: pkg.pname or pkg.name or "<unnamed>") allInputs);

in

pkgs.mkShell {
  name = "pbg-dev-shell";

  buildInputs = allInputs;

  shellHook = ''
    echo "welcome to the pixel-backup-gang dev shell"
    echo ""
    echo "packages included in this shell:${inputPackageNames}"
    echo ""
  '';
}
