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
    enable = mkEnableOption "Enable Bitbucket runner module";

    user = mkOption {
      type = types.str;
      default = "bitbucket-runner";
      description = "User to run Bitbucket runners";
    };

    group = mkOption {
      type = types.str;
      default = "bitbucket-runner";
      description = "Group for Bitbucket runners";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages available to runner environments";
    };

    runners = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            accountUuid = mkOption {
              type = types.str;
              description = "Account UUID";
            };
            repositoryUuid = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Repository UUID";
            };
            runnerUuid = mkOption {
              type = types.str;
              description = "Runner UUID";
            };
            OAuthClientId = mkOption {
              type = types.str;
              description = "OAuth Client ID";
            };
            OAuthClientSecret = mkOption {
              type = types.str;
              description = "OAuth Client Secret";
            };
            workingDirectory = mkOption {
              type = types.str;
              default = "/tmp";
              description = "Working directory";
            };
            runtime = mkOption {
              type = types.enum [
                "linux-shell"
                "linux-docker"
              ];
              default = "linux-shell";
              description = "Runtime environment";
            };
            extraFlags = mkOption {
              type = types.str;
              default = "";
              description = "Extra flags";
            };
          };
        }
      );
      default = { };
      description = "Configuration for Bitbucket Runners.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      createHome = true;
      home = "/home/${cfg.user}";
      group = cfg.group;
      description = "Bitbucket Runner User";
    };

    users.groups.${cfg.group} = { };

    systemd.services = lib.mapAttrs' (
      name: runner:
      let
        execArgs = [
          "--accountUuid {${runner.accountUuid}}"
          "--runnerUuid {${runner.runnerUuid}}"
          "--OAuthClientId ${runner.OAuthClientId}"
          "--OAuthClientSecret ${runner.OAuthClientSecret}"
          "--runtime ${runner.runtime}"
          "--workingDirectory ${runner.workingDirectory}"
        ] ++ lib.optional (runner.repositoryUuid != null) "--repositoryUuid {${runner.repositoryUuid}}";
      in
      nameValuePair "bitbucket-runner-${name}" {
        description = "Bitbucket Runner ${name}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = cfg.extraPackages;
        serviceConfig = {
          ExecStart = "${bitbucketRunner}/bin/bitbucket-runner-linux-shell ${lib.concatStringsSep " " execArgs}";
          User = cfg.user;
          Group = cfg.group;
          Restart = "on-failure";
        };
      }
    ) (filterAttrs (_: runner: runner.runtime == "linux-shell") cfg.runners);

    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: runner:
      nameValuePair "bitbucket-runner-${name}" {
        image = "docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner";
        volumes = [ "/tmp:${runner.workingDirectory}" ];
        environment =
          {
            ACCOUNT_UUID = runner.accountUuid;
            RUNNER_UUID = runner.runnerUuid;
            OAUTH_CLIENT_ID = runner.OAuthClientId;
            OAUTH_CLIENT_SECRET = runner.OAuthClientSecret;
            WORKING_DIRECTORY = runner.workingDirectory;
          }
          // lib.optionalAttrs (runner.repositoryUuid != null) {
            REPOSITORY_UUID = runner.repositoryUuid;
          };
      }
    ) (filterAttrs (_: runner: runner.runtime == "linux-docker") cfg.runners);
  };

}
