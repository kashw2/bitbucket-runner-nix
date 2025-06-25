{
  buildFHSEnv,
  fetchzip,
  retry,
  writeScriptBin,
  writeShellScript,
  extraPkgs ? [ ],
}:
let
  version = "3.24.0";
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz";
    hash = "sha256-m16jrFwa+6bTMj7l70WN2LH3kofdJj8/tDJBR17kACk=";
    stripRoot = false;
  };
  # the clone script that the runner generates executes a command of the form
  # retry 6 git clone --branch="BRANCHNAME" -- depth 50 ...
  # I'm not sure where such a retry script can be found,
  # so we just adapt a different retry program to do the job.
  retry-workaround = writeScriptBin "retry" ''
    exec -- ${retry}/bin/retry --times="$1" -- ''${@:2}
  '';
in
buildFHSEnv {
  name = "bitbucket-runner-linux-shell";
  targetPkgs =
    pkgs:
    (with pkgs; [
      jre
      bash
      git
      util-linux
      nix # run nix commands as part of pipeline.
      retry-workaround
    ])
    ++ extraPkgs;
  runScript = writeShellScript "bitbucket-runner-linux-shell-start" ''
    cd "${src}/bin"
    exec bash ./start.sh "$@"
  '';
}
