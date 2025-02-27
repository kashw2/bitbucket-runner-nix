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
        type = types.nullOr types.str;
        description = "The repository UUID for the Bitbucket runner";
        default = null;
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
        type = types.enum [
          "linux-shell"
          "linux-docker"
        ];
        default = "linux-shell";
        description = "The runtime environment for the Bitbucket runner";
      };
      extraFlags = mkOption {
        type = types.str;
        default = "";
        description = "Additional flags to pass to the Bitbucket runner";
      };
    };
    extraPackages = mkOption {
      type = types.listOf types.package;
      description = "Additional packages to make available to pipelines";
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      description = "Bitbucket Runner Linux Shell User";
      group = cfg.group;
      # For certain File System actions, the runner may need an actual user
      # An example is Nix operations (eg Colmena, deploy-rs etc)
      isNormalUser = true;
      createHome = true;
      home = "/home/${cfg.user}";
    };

    users.groups.${cfg.group} = { };

    systemd.services.bitbucket-runner = mkIf (cfg.flags.runtime == "linux-shell") {
      description = "Bitbucket Runner Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = cfg.extraPackages;
      serviceConfig = {
        ExecStart = ''
          ${bitbucketRunner}/bin/bitbucket-runner-linux-shell \
            --accountUuid {${cfg.flags.accountUuid}} \
            --runnerUuid {${cfg.flags.runnerUuid}} \
            --OAuthClientId ${cfg.flags.OAuthClientId} \
            --OAuthClientSecret ${cfg.flags.OAuthClientSecret} \
            --runtime ${cfg.flags.runtime} \
            --workingDirectory ${cfg.flags.workingDirectory} \
            ${lib.optionalString (
              cfg.flags.repositoryUuid != null
            ) "--repositoryUuid {${cfg.flags.repositoryUuid}}"}
        '';
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
      };
    };

    virtualisation.oci-containers = mkIf (cfg.flags.runtime == "linux-docker") {
      backend = "docker";
      containers = {
        bitbucket-runner = {
          image = "docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner";
          volumes = [
            "/tmp:${cfg.flags.workingDirectory}"
          ];
          environment =
            {
              ACCOUNT_UUID = cfg.flags.accountUuid;
              RUNNER_UUID = cfg.flags.runnerUuid;
              OAUTH_CLIENT_ID = cfg.flags.OAuthClientId;
              OAUTH_CLIENT_SECRET = cfg.flags.OAuthClientSecret;
              WORKING_DIRECTORY = cfg.flags.workingDirectory;
            }
            ++ lib.optionalAttrs (cfg.flags.repositoryUuid != null) {
              REPOSITORY_UUID = cfg.flags.repositoryUuid;
            };
        };
      };
    };
  };
}
