{ pkgs ? import <nixpkgs> {} }:

let

  pbgPackage = import ./default.nix { inherit pkgs; };

  adbPackage = pkgs.android-tools;

  allInputs =
    (pbgPackage.buildInputs or [])
    ++ (pbgPackage.nativeBuildInputs or [])
    ++ [ adbPackage ];

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
