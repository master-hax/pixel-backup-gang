{
  description = "pixel-backup-gang: NAND-wear mitigation scripts + custom NFS-enabled/rooted kernel builds for Pixel/Pixel XL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      # thin wrapper around default.nix/shell.nix - both already accept a
      # `pkgs` argument, so non-flake usage (nix-build/nix-shell against
      # <nixpkgs>) keeps working unchanged alongside this
      packages = forEachSystem (system:
        import ./default.nix { pkgs = import nixpkgs { inherit system; }; }
      );

      devShells = forEachSystem (system: {
        default = import ./shell.nix { pkgs = import nixpkgs { inherit system; }; };
      });
    };
}
