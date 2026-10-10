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
asset="tori-cli-$version-macos-universal.tar.gz"
mkdir -p "$dir"
gh release download "v$version" --repo gettori/tori --pattern "$asset" --dir "$dir"
tar -xzf "$dir/$asset" -C "$dir"
echo "$version"
