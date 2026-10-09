#!/bin/sh
# Usage: tori-cli.sh <version> <dir>
# Puts the tori CLI from release v<version> at <dir>/tori. Needs GH_TOKEN.
set -eu
version=$1
dir=$2
asset="tori-cli-$version-macos-universal.tar.gz"
mkdir -p "$dir"
gh release download "v$version" --repo gettori/tori --pattern "$asset" --dir "$dir"
tar -xzf "$dir/$asset" -C "$dir"
