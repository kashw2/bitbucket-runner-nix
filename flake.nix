{
  description = "Nix Bitbucket Runner";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs =
    inputs@{
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}.pkgs;
    in
    {
      packages.${system} = {
        default = self.outputs.packages.${system}.bitbucket-runner;
        bitbucket-runner = pkgs.callPackage ./package.nix { };
      };
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nix-update
          pkgs.git
        ];
      };
      nixosModules.bitbucket-runner.imports = [ ./default.nix ];
    };
}
