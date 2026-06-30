#!/usr/bin/env bash
# Bump a GitHub-release-based cask to the latest upstream version.
# Usage: scripts/bump-cask.sh <cask-file> <gh-repo> <arm-asset> <intel-asset> <tag-prefix>
# Tag is assumed to be "<tag-prefix><version>", e.g. aio-coding-hub-v0.60.2
set -euo pipefail

CASK="${1:?cask file}"
REPO="${2:?owner/repo}"
ARM_ASSET="${3:?arm asset name}"
INTEL_ASSET="${4:?intel asset name}"
PREFIX="${5:?tag prefix}"

cur=$(grep -m1 'version "' "$CASK" | sed -E 's/.*version "([^"]+)".*/\1/')
tag=$(gh api "repos/$REPO/releases/latest" --jq .tag_name)
new="${tag#$PREFIX}"

if [ -z "$new" ] || [ "$new" = "$tag" ]; then
  echo "could not parse version from tag '$tag' (prefix '$PREFIX')" >&2
  exit 1
fi

if [ "$cur" = "$new" ]; then
  echo "already up-to-date ($cur)"
  exit 0
fi

base="https://github.com/$REPO/releases/download/$tag"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/arm"   "$base/$ARM_ASSET"
curl -fsSL -o "$tmp/intel" "$base/$INTEL_ASSET"
arm=$(shasum -a 256 "$tmp/arm"   | cut -d' ' -f1)
intel=$(shasum -a 256 "$tmp/intel" | cut -d' ' -f1)

# version
sed -i.bak -E "s/version \"[^\"]+\"/version \"$new\"/" "$CASK" && rm -f "$CASK.bak"

# sha256: replace inside the matching on_arm / on_intel block
awk -v arm="$arm" -v intel="$intel" '
  /on_arm do/   { blk="arm" }
  /on_intel do/ { blk="intel" }
  /sha256 "/ {
    if (blk=="arm")   { sub(/sha256 "[^"]+"/, "sha256 \"" arm "\""); blk="" }
    else if (blk=="intel") { sub(/sha256 "[^"]+"/, "sha256 \"" intel "\""); blk="" }
  }
  { print }
' "$CASK" > "$CASK.tmp" && mv "$CASK.tmp" "$CASK"

echo "bumped $cur -> $new"
echo "arm=$arm"
echo "intel=$intel"
