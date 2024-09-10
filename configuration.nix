{ config, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    ./default.nix  
  ];
  services = {
    # Enable SSH
    openssh.enable = true;

    # Enable Bitbucket Runner Linux Shell Service
    bitbucket-runner-linux-shell.enable = true;

    bitbucket-runner-linux-shell.user = "bitbucket-runner-linux-shell";
    bitbucket-runner-linux-shell.group = "bitbucket-runner-linux-shell";

    # Flags for the Bitbucket runner
    bitbucket-runner-linux-shell.flags = {
      accountUuid = "";
      repositoryUuid = "";
      runnerUuid = "";
      OAuthClientId = "";
      OAuthClientSecret = "";
      workingDirectory = "/tmp"; # default, but can be overridden
      runtime = "linux-shell"; #     ^^^
      extraFlags = ""; #             ^^^
    };
  };
}
