{
  description = "Nix Bitbucket Runner Linux Shell";

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
            pkgs;
        };
      };
      nixosModules = with nixpkgs.legacyPackages.${system}.pkgs; {
        bitbucket-runner = import ./default.nix {
          inherit lib pkgs config;
        };
      };
    };
}
