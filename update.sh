#!/usr/bin/env bash
set -euo pipefail

CHANGELOG_URL="https://product-downloads.atlassian.com/software/bitbucket/pipelines/CHANGELOG.md"

# Prefer $PWD (nix-update sets cwd to the flake root; direct runs are typically
# from the repo root too). Fall back to the script's directory otherwise.
if [[ -f "$PWD/package.nix" ]]; then
  PACKAGE_NIX="$PWD/package.nix"
else
  PACKAGE_NIX="$(dirname "$(realpath "$0")")/package.nix"
fi

echo "Fetching changelog..."
version=$(curl -sSf "$CHANGELOG_URL" | grep -m1 -oP '^## \K[0-9]+\.[0-9]+\.[0-9]+')

if [[ -z "$version" ]]; then
  echo "Failed to extract version from changelog" >&2
  exit 1
fi

current=$(grep -oP 'version = "\K[^"]+' "$PACKAGE_NIX")

echo "Current: $current"
echo "Latest:  $version"

if [[ "$version" == "$current" ]]; then
  echo "Already up to date."
  exit 0
fi

tarball="https://product-downloads.atlassian.com/software/bitbucket/pipelines/atlassian-bitbucket-pipelines-runner-${version}.tar.gz"

echo "Prefetching $tarball..."
prefetch=$(nix-prefetch-url --unpack --type sha256 "$tarball")
sri=$(nix hash convert --hash-algo sha256 --to sri "$prefetch")

echo "New hash: $sri"

sed -i "s|version = \"[^\"]*\";|version = \"$version\";|" "$PACKAGE_NIX"
sed -i "s|hash = \"[^\"]*\";|hash = \"$sri\";|" "$PACKAGE_NIX"

echo "Updated package.nix to $version"
