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
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "OAuth Client ID. Prefer environmentFile to avoid secrets landing in the Nix store.";
            };
            OAuthClientSecret = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "OAuth Client Secret. Prefer environmentFile to avoid secrets landing in the Nix store.";
            };
            environmentFile = lib.mkOption {
              type = lib.types.nullOr lib.types.path;
              default = null;
              description = ''
                Path to a file containing OAuth credentials in KEY=VALUE format:

                  OAUTH_CLIENT_ID=your-client-id
                  OAUTH_CLIENT_SECRET=your-client-secret

                Provision this file outside the Nix store using a secrets
                manager such as agenix or sops-nix. Mutually exclusive with
                OAuthClientId and OAuthClientSecret.
              '';
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
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: runner: [
        {
          assertion =
            runner.environmentFile != null
            || (runner.OAuthClientId != null && runner.OAuthClientSecret != null);
          message = "bitbucket-runner: runner '${name}' must set either environmentFile or both OAuthClientId and OAuthClientSecret.";
        }
        {
          assertion =
            runner.environmentFile == null
            || (runner.OAuthClientId == null && runner.OAuthClientSecret == null);
          message = "bitbucket-runner: runner '${name}' cannot set environmentFile together with OAuthClientId or OAuthClientSecret.";
        }
      ]) cfg.runners
    );

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
        oauthArgs =
          if runner.environmentFile != null then
            [
              "--OAuthClientId $OAUTH_CLIENT_ID"
              "--OAuthClientSecret $OAUTH_CLIENT_SECRET"
            ]
          else
            [
              "--OAuthClientId ${runner.OAuthClientId}"
              "--OAuthClientSecret ${runner.OAuthClientSecret}"
            ];
        execArgs =
          [
            "--accountUuid {${runner.accountUuid}}"
            "--runnerUuid {${runner.runnerUuid}}"
          ]
          ++ oauthArgs
          ++ [
            "--runtime ${runner.runtime}"
            "--workingDirectory ${runner.workingDirectory}"
          ]
          ++ lib.optional (runner.repositoryUuid != null) "--repositoryUuid {${runner.repositoryUuid}}"
          ++ lib.optional (runner.extraFlags != "") runner.extraFlags;
      in
      lib.nameValuePair "bitbucket-runner-${name}" {
        description = "Bitbucket Runner ${name}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = cfg.extraPackages;
        serviceConfig =
          {
            ExecStart = "${bitbucketRunner}/bin/bitbucket-runner-linux-shell ${lib.concatStringsSep " " execArgs}";
            User = cfg.user;
            Group = cfg.group;
            Restart = "on-failure";
          }
          // lib.optionalAttrs (runner.environmentFile != null) {
            EnvironmentFile = runner.environmentFile;
          };
      }
    ) (lib.filterAttrs (_: runner: runner.runtime == "linux-shell") cfg.runners);

    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: runner:
      lib.nameValuePair "bitbucket-runner-${name}" {
        image = "docker-public.packages.atlassian.com/sox/atlassian/bitbucket-pipelines-runner";
        volumes = [ "/tmp:${runner.workingDirectory}" ];
        environmentFiles = lib.optional (runner.environmentFile != null) runner.environmentFile;
        environment =
          {
            ACCOUNT_UUID = runner.accountUuid;
            RUNNER_UUID = runner.runnerUuid;
            WORKING_DIRECTORY = runner.workingDirectory;
          }
          // lib.optionalAttrs (runner.OAuthClientId != null) {
            OAUTH_CLIENT_ID = runner.OAuthClientId;
            OAUTH_CLIENT_SECRET = runner.OAuthClientSecret;
          }
          // lib.optionalAttrs (runner.repositoryUuid != null) {
            REPOSITORY_UUID = runner.repositoryUuid;
          };
      }
    ) (lib.filterAttrs (_: runner: runner.runtime == "linux-docker") cfg.runners);
  };

}
