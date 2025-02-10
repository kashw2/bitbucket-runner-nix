{
  writeShellScript,
  fetchzip,
  buildFHSEnv,
}:
let
  version = "3.16.0";
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz";
    hash = "sha256-bY5Qz2v6rN0VNL0fYsVjqmKDLjOYn00dFqa8GDeql3Y=";
    stripRoot = false;
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
      util-linux
    ]);
  runScript = writeShellScript "bitbucket-runner-linux-shell-start" ''
    cd "${src}/bin"
    exec bash ./start.sh "$@"
  '';
}
