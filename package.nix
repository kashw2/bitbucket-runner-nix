{
  writeShellScript,
  fetchzip,
  buildFHSEnv,
}:
let
  version = "3.10.0";
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz";
    stripRoot = false;
    hash = "sha256-nFRh6hy49Vg8dMfD0ZPyu9ZGuWaLtmxcPXaDl5ePFeM=";
  };
in
buildFHSEnv {
  name = "bitbucket-runner-linux-shell";
  targetPkgs =
    pkgs:
    (with pkgs; [
      jre
      bash
      git
    ]);
  runScript = writeShellScript "bitbucket-runner-linux-shell-start" ''
    cd "${src}/bin"
    exec bash ./start.sh "$@"
  '';
}
