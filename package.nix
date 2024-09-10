{ writeShellScript, fetchzip, buildFHSEnv}:
let
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-3.1.0.tar.gz";
    stripRoot = false;

    hash = "sha256-8B5pgE/sb0mv/ofYidq0tKwXMIdEP34aY34xKLlQYBE=";
  };
in
  buildFHSEnv {
    name = "bitbucket-runner-linux-shell";
    targetPkgs = pkgs: (with pkgs; [
      jre
      bash
      git
    ]);
    runScript = writeShellScript "bitbucket-runner-linux-shell-start" 
    ''
    cd "${src}/bin"
    exec bash ./start.sh "$@"
    '';
  }
