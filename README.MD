# Nix Bitbucket Runner Linux Shell

A NixOS Package and Module that exposes the Bitbucket Runner as a Systemd Service via Nix.

# Usage

1) Add the following to your flake.nix inputs:

```nix
bitbucket-runner-linux-shell.url = "github:MNRMax/nix-bitbucket-runner-linux-shell";
```

2) Add the following to your flake.nix's nixosConfiguration configuration module:

```nix
bitbucket-runner-linux-shell.nixosModules.bitbucket-runner;
```

3) Add the following to your configuration.nix:

```nix
services.bitbucket-runner = {
    enable = true
    flags = {
        accountUuid = "YOUR UUID";
        repositoryUuid = "YOUR REPOSITORY UUID";
        runnerUuid = "YOUR RUNNER UUID";
        OAuthClientId = "YOUR OAUTH CLIENT ID";
        OAuthClientSecret = "YOUR OAUTH CLIENT SECRET";
    };
};
```