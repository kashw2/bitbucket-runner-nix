{
  description = "Nix Bitbucket Runner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} = with nixpkgs.legacyPackages.${system}.pkgs; {
        default = bitbucket-runner;
        bitbucket-runner = import ./package.nix {
          inherit
            writeShellScript
            fetchzip
            buildFHSEnv
            ;
        };
      };
      nixosModules.bitbucket-runner.imports = [ ./default.nix ];
    };
}
