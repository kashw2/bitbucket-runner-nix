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
        default = import ./package.nix {
          inherit
            writeShellScript
            fetchzip
            buildFHSEnv
            ;
        };
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
