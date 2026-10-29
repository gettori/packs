#!/bin/sh
# Usage: tori-cli.sh <version>|newest <dir>
# Puts the tori CLI from release v<version> at <dir>/tori, or from the newest
# release with `newest`, and prints the version it took. Needs GH_TOKEN.
set -eu
version=$1
dir=$2
if [ "$version" = newest ]; then
  # Not `gh release view`: GitHub's latest release skips pre-releases, and
  # every Tori release so far is one.
  tag=$(gh release list --repo gettori/tori --limit 1 --exclude-drafts --json tagName -q '.[0].tagName')
  version=${tag#v}
fi
case $(uname -m) in
  arm64 | aarch64) arch=arm64 ;;
  *) arch=x64 ;;
esac
# Releases up to 26.1015.0-alpha ship one universal CLI, later ones one per
# arch. validate.yml still needs the oldest supported release, so take either.
assets=$(gh release view "v$version" --repo gettori/tori --json assets -q '.assets[].name')
asset=
for candidate in "tori-cli-$version-macos-$arch.tar.gz" "tori-cli-$version-macos-universal.tar.gz"; do
  if printf '%s\n' "$assets" | grep -qFx "$candidate"; then
    asset=$candidate
    break
  fi
done
if [ -z "$asset" ]; then
  echo "tori-cli.sh: v$version has no tori-cli asset for macos-$arch or macos-universal" >&2
  exit 1
fi
mkdir -p "$dir"
gh release download "v$version" --repo gettori/tori --pattern "$asset" --dir "$dir"
tar -xzf "$dir/$asset" -C "$dir"
echo "$version"
