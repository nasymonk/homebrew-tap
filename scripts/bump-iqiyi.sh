#!/usr/bin/env bash
# Bump the iqiyi cask by scraping its download page.
# The page exposes both the version number and the dmg URL
# (iQIYIMedia_<build>.dmg, where <build> is unrelated to the version).
set -euo pipefail

CASK="${1:-Casks/iqiyi.rb}"
PAGE="https://app.iqiyi.com/mac/player/index.html"

html=$(curl -fsSL "$PAGE")

new_url=$(grep -oE 'https://static-d\.iqiyi\.com/ext/common/iQIYIMedia_[0-9]+\.dmg' <<<"$html" | head -1)
new_ver=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"$html" | head -1)

if [ -z "$new_url" ] || [ -z "$new_ver" ]; then
  echo "failed to parse url/version from page (url='$new_url' ver='$new_ver')" >&2
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
  -e "s|url \"https://static-d\.iqiyi\.com[^\"]+\"|url \"$new_url\"|" \
  "$CASK" && rm -f "$CASK.bak"

echo "bumped $cur_ver -> $new_ver"
echo "url=$new_url"
echo "sha256=$sha"
