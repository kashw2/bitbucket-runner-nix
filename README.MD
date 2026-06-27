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
  enable = true;
  user = "bitbucket-runner"; # Optional
  group = "bitbucket-runner"; # Optional
  extraPackages = [
    pkgs.terraform
    pkgs.nodejs
    pkgs.go
    pkgs.gcc
  ]; # Optional
  runners = {
    runner-1 = {
      accountUuid = "YOUR ACCOUNT UUID";
      runnerUuid = "YOUR RUNNER 1 UUID";
      environmentFile = "/run/secrets/bitbucket-runner-1"; # Preferred and secure; managed by agenix/sops-nix
      OAuthClientId = "YOUR OAUTH CLIENT ID"; # Alternative if not using /run/secrets, insecure, cannot be used in conjunction with `environmentFile`
      OAuthClientSecret = "YOUR OAUTH CLIENT SECRET"; # Alternative if not using /run/secrets, insecure, cannot be used in conjunction with `environmentFile`
      runtime = "linux-shell";
    };
    runner-2 = {
      accountUuid = "YOUR ACCOUNT UUID";
      runnerUuid = "YOUR RUNNER 2 UUID";
      environmentFile = "/run/secrets/bitbucket-runner-2"; # Preferred and secure; managed by agenix/sops-nix
      OAuthClientId = "YOUR OAUTH CLIENT ID"; # Alternative if not using /run/secrets, insecure, cannot be used in conjunction with `environmentFile`
      OAuthClientSecret = "YOUR OAUTH CLIENT SECRET"; # Alternative if not using /run/secrets, insecure, cannot be used in conjunction with `environmentFile`
      runtime = "linux-docker";
    };
  };
};
```

Each `environmentFile` must contain the runner's OAuth credentials in `KEY=VALUE` format:

```
OAUTH_CLIENT_ID=your-client-id
OAUTH_CLIENT_SECRET=your-client-secret
```

Provision these files outside the Nix store using a secrets manager such as [agenix](https://github.com/ryantm/agenix) or [sops-nix](https://github.com/Mic92/sops-nix).
You cannot use `OAuthClientId` or `OAuthClientSecret` in conjunction with `environmentFile`

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
