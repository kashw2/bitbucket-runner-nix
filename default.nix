# Bitbucket Runner Linux Shell Nix Module

{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.bitbucket-runner-linux-shell;
  bitbucketRunner = pkgs.callPackage ./package.nix { };
in
{
  options = {
    services.bitbucket-runner-linux-shell = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Bitbucket runner service";
      };

      user = mkOption {
        type = types.str;
        default = "bitbucket-runner-linux-shell";
        description = "The user that runs the Bitbucket runner service";
      };

      group = mkOption {
        type = types.str;
        default = "bitbucket-runner-linux-shell";
        description = "The group for the Bitbucket runner service";
      };

      flags = {
        accountUuid = mkOption {
          type = types.str;
          description = "The account UUID for the Bitbucket runner";
        };
        repositoryUuid = mkOption {
          type = types.str;
          description = "The repository UUID for the Bitbucket runner";
        };
        runnerUuid = mkOption {
          type = types.str;
          description = "The runner UUID for the Bitbucket runner";
        };
        OAuthClientId = mkOption {
          type = types.str;
          description = "The OAuth Client ID for Bitbucket authentication";
        };
        OAuthClientSecret = mkOption {
          type = types.str;
          description = "The OAuth Client Secret for Bitbucket authentication";
        };
        workingDirectory = mkOption {
          type = types.str;
          default = "/tmp";
          description = "The working directory for the Bitbucket runner";
        };
        runtime = mkOption {
          type = types.str;
          default = "linux-shell";
          description = "The runtime environment for the Bitbucket runner";
        };
        extraFlags = mkOption {
          type = types.str;
          default = "";
          description = "Additional flags to pass to the Bitbucket runner";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    users.users = {
      "bitbucket-runner-linux-shell" = {
        description = "Bitbucket Runner Linux Shell user";
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = {
      "bitbucket-runner-linux-shell" = {};
    };

    systemd.services.bitbucket-runner-linux-shell = {
      description = "Bitbucket Runner Linux Shell Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${bitbucketRunner}/bin/bitbucket-runner \
            --accountUuid {${cfg.flags.accountUuid}} \
            --repositoryUuid {${cfg.flags.repositoryUuid}} \
            --runnerUuid {${cfg.flags.runnerUuid}} \
            --OAuthClientId ${cfg.flags.OAuthClientId} \
            --OAuthClientSecret ${cfg.flags.OAuthClientSecret} \
            --runtime ${cfg.flags.runtime} \
            --workingDirectory ${cfg.flags.workingDirectory}
        '';
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
      };
    };
  };
}
