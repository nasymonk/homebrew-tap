#!/usr/bin/env bash
# Bump the buhocleaner cask from its Sparkle appcast.
# The appcast exposes the version and a build-numbered dmg URL.
set -euo pipefail

CASK="${1:-Casks/buhocleaner.rb}"
FEED="https://www.drbuho.com/buho-public-files/buhocleaner/appcast.xml"

xml=$(curl -fsSL "$FEED")
new_ver=$(grep -oE 'sparkle:shortVersionString="[^"]+"' <<<"$xml" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
new_url=$(grep -oE 'url="https://[^"]+\.dmg"' <<<"$xml" | head -1 | sed -E 's/url="([^"]+)"/\1/')

if [ -z "$new_ver" ] || [ -z "$new_url" ]; then
  echo "failed to parse appcast (ver='$new_ver' url='$new_url')" >&2
  exit 1
fi

cur_ver=$(grep -m1 'version "' "$CASK" | sed -E 's/.*version "([^"]+)".*/\1/')
cur_url=$(grep -m1 'url "' "$CASK" | sed -E 's/.*url "([^"]+)".*/\1/')

if [ "$cur_ver" = "$new_ver" ] && [ "$cur_url" = "$new_url" ]; then
  echo "already up-to-date ($cur_ver)"
  exit 0
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/app.dmg" "$new_url"
sha=$(shasum -a 256 "$tmp/app.dmg" | cut -d' ' -f1)

sed -i.bak -E \
  -e "s|version \"[^\"]+\"|version \"$new_ver\"|" \
  -e "s|sha256 \"[^\"]+\"|sha256 \"$sha\"|" \
  -e "s|url \"https://drbuho\.net[^\"]+\"|url \"$new_url\"|" \
  "$CASK" && rm -f "$CASK.bak"

echo "bumped $cur_ver -> $new_ver"
echo "url=$new_url"
echo "sha256=$sha"
