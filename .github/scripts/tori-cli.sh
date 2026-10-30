#!/bin/sh
# Usage: tori-cli.sh <version>|newest <dir>
# Puts the tori CLI from the macOS release of <version> at <dir>/tori, or from
# the newest macOS release with `newest`, and prints the version it took. Needs
# GH_TOKEN.
set -eu
version=$1
dir=$2
# Releases were tagged v<version> before each platform got its own prefix, and
# the newest release may be Android's.
if [ "$version" = newest ]; then
  tags=$(gh release list --repo gettori/tori --limit 30 --exclude-drafts --json tagName \
    -q '[.[].tagName | select(startswith("macos-v") or startswith("v"))][0] // empty')
  if [ -z "$tags" ]; then
    echo "tori-cli.sh: none of the 30 newest gettori/tori releases is a macOS one" >&2
    exit 1
  fi
else
  tags="macos-v$version v$version"
fi
err=$(mktemp)
trap 'rm -f "$err"' EXIT
assets=
for tag in $tags; do
  assets=$(gh release view "$tag" --repo gettori/tori --json assets -q '.assets[].name' 2>"$err") && break
  assets=
done
if [ -z "$assets" ]; then
  echo "tori-cli.sh: no macOS release for $version on gettori/tori: $(cat "$err")" >&2
  exit 1
fi
version=${tag#macos-}
version=${version#v}
case $(uname -m) in
  arm64 | aarch64) arch=arm64 ;;
  *) arch=x64 ;;
esac
# Releases up to 26.1015.0-alpha ship one universal CLI, later ones one per
# arch. validate.yml still needs the oldest supported release, so take either.
asset=
for candidate in "tori-cli-$version-macos-$arch.tar.gz" "tori-cli-$version-macos-universal.tar.gz"; do
  if printf '%s\n' "$assets" | grep -qFx "$candidate"; then
    asset=$candidate
    break
  fi
done
if [ -z "$asset" ]; then
  echo "tori-cli.sh: $tag has no tori-cli asset for macos-$arch or macos-universal" >&2
  exit 1
fi
mkdir -p "$dir"
gh release download "$tag" --repo gettori/tori --pattern "$asset" --dir "$dir"
tar -xzf "$dir/$asset" -C "$dir"
echo "$version"
