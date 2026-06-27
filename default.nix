# Bitbucket Runner Linux Shell Nix Module

{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.services.bitbucket-runner;
  bitbucketRunner = pkgs.callPackage ./package.nix { };
in
{
  options.services.bitbucket-runner = {
    enable = lib.mkEnableOption "Bitbucket runner module";

    user = lib.mkOption {
      type = lib.types.str;
      default = "bitbucket-runner";
      description = "User to run Bitbucket runners";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "bitbucket-runner";
      description = "Group for Bitbucket runners";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages available to runner environments";
    };

    runners = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            accountUuid = lib.mkOption {
              type = lib.types.str;
              description = "Account UUID";
            };
            repositoryUuid = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Repository UUID";
            };
            runnerUuid = lib.mkOption {
              type = lib.types.str;
              description = "Runner UUID";
            };
            OAuthClientId = lib.mkOption {
              type = lib.types.str;
              description = "OAuth Client ID";
            };
            OAuthClientSecret = lib.mkOption {
              type = lib.types.str;
              description = "OAuth Client Secret";
            };
            workingDirectory = lib.mkOption {
              type = lib.types.str;
              default = "/tmp";
              description = "Working directory";
            };
            runtime = lib.mkOption {
              type = lib.types.enum [
                "linux-shell"
                "linux-docker"
              ];
              default = "linux-shell";
              description = "Runtime environment";
            };
            extraFlags = lib.mkOption {
              type = lib.types.str;
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

  config = lib.mkIf cfg.enable {
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
      lib.nameValuePair "bitbucket-runner-${name}" {
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
    ) (lib.filterAttrs (_: runner: runner.runtime == "linux-shell") cfg.runners);

    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: runner:
      lib.nameValuePair "bitbucket-runner-${name}" {
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
    ) (lib.filterAttrs (_: runner: runner.runtime == "linux-docker") cfg.runners);
  };

}
