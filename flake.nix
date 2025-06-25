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
    in
    {
      packages.${system} = {
        default = self.outputs.packages.${system}.bitbucket-runner;
        bitbucket-runner = nixpkgs.legacyPackages.${system}.pkgs.callPackage ./package.nix { };
      };
      nixosModules.bitbucket-runner.imports = [ ./default.nix ];
    };
}
