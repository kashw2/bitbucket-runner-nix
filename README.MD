# Bitbucket Runner Nix

A NixOS Package and Module that exposes the Bitbucket Runner as a Systemd Service via Nix.

[![Nix](https://github.com/kashw2/bitbucket-runner-nix/actions/workflows/nix.yml/badge.svg)](https://github.com/kashw2/bitbucket-runner-nix/actions/workflows/nix.yml)

---

# Usage

### As a Systemd Service

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
    bitbucket-runner = {
      enable = true;
      user = "bitbucket-runner";
      group = "bitbucket-runner"; # Optional if default
      extraPackages = [
        pkgs.terraform
      ];
      runners = {
        runner-1 = {
          accountUuid = "YOUR ACCOUNT UUID";
          runnerUuid = "YOUR RUNNER UUID";
          OAuthClientId = "YOUR OAUTH CLIENT ID";
          OAuthClientSecret = "YOUR OAUTH CLIENT SECRET";
          runtime = "linux-shell";
        };
        runner-2 = {
          accountUuid = "YOUR ACCOUNT UUID";
          runnerUuid = "YOUR RUNNER UUID";
          OAuthClientId = "YOUR OAUTH CLIENT ID";
          OAuthClientSecret = "YOUR OAUTH CLIENT SECRET"; 
          runtime = "linux-docker";
        };
      };
    };
```

### Invoked via shell

```shell
nix shell github:kashw2/bitbucket-runner-nix#bitbucket-runner \ 
    -c sh \
    -c "bitbucket-runner-linux-shell \ 
    --accountUuid A \
    --runnerUuid B \
    --OAuthClientId C \
    --OAuthClientSecret D \
    --workingDirectory E \
    --runtime linux-shell"
 ```

---