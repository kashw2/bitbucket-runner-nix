# Bitbucket Runner Nix

A NixOS Package and Module that exposes the Bitbucket Runner as a Systemd Service via Nix.

# Usage

1) Add the following to your flake.nix inputs:

```nix
bitbucket-runner-nix.url = "github:kashw2/bitbucket-runner-nix";
```

2) Add the following to your flake.nix's nixosConfiguration configuration module:

```nix
bitbucket-runner-nix.nixosModules.bitbucket-runner;
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