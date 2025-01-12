{
  writeShellScript,
  fetchzip,
  buildFHSEnv,
}:
let
  version = "3.15.0";
  src = fetchzip {
    url = "https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz";
    hash = "sha256-Hz6yZpnE4W0ZVse7+pKhPaUsOTfH8IQ10EGzNdkpkv8=";
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
