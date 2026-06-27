{
  description = "Nix Bitbucket Runner";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    inputs@{
      self,
      nixpkgs,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system: {
        default = self.outputs.packages.${system}.bitbucket-runner;
        bitbucket-runner = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
      });
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [
            nixpkgs.legacyPackages.${system}.nix-update
            nixpkgs.legacyPackages.${system}.git
          ];
        };
      });
      nixosModules.bitbucket-runner.imports = [ ./default.nix ];
    };
}
