# Bitbucket Runner Linux Shell Nix Module

{
  lib,
  pkgs,
  config,
  ...
}:

with lib;

let
  cfg = config.services.bitbucket-runner;
  bitbucketRunner = pkgs.callPackage ./package.nix { };
in
{
  imports = [ ];

  options.services.bitbucket-runner = {
    enable = mkEnableOption "bitbucket-runner";

    user = mkOption {
      type = types.str;
      default = "bitbucket-runner";
      description = "The user that runs the Bitbucket runner service";
    };

    group = mkOption {
      type = types.str;
      default = "bitbucket-runner";
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

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "Bitbucket Runner Linux Shell User";
      group = cfg.group;
      isSystemUser = true;
    };

    users.groups.${cfg.group} = { };

    systemd.services.bitbucket-runner = {
      description = "Bitbucket Runner Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${bitbucketRunner}/bin/bitbucket-runner-linux-shell \
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
