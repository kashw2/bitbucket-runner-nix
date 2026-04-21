{
  buildFHSEnv,
  fetchzip,
  retry,
  writeScriptBin,
  writeShellScript,
  extraPkgs ? [ ],
}:
let
  version = "5.7.0";
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz";
    hash = "sha256-DY77aCrhuMf5zQzAPjNbmmLcnkewQ/IYHnDRshSvkdA=";
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
  pname = "bitbucket-runner-linux-shell";
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
  passthru = {
    inherit version;
    updateScript = ./update.sh;
  };
  runScript = writeShellScript "bitbucket-runner-linux-shell-start" ''
    cd "${src}/bin"
    exec bash ./start.sh "$@"
  '';

}
