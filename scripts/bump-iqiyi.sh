#!/usr/bin/env bash
# Bump the iqiyi cask by scraping its download page.
# 页面上的"最新版本"文案不可信（爱奇艺偶尔改文案但未上传新 dmg），
# 因此以 dmg 内 App Bundle 的 CFBundleShortVersionString 为权威版本。
set -euo pipefail

CASK="${1:-Casks/iqiyi.rb}"
PAGE="https://app.iqiyi.com/mac/player/index.html"

html=$(curl -fsSL "$PAGE")

# dmg 地址：static-d.iqiyi.com 域名的 iQIYIMedia_<build>.dmg
new_url=$(grep -oE 'https://static-d\.iqiyi\.com/ext/common/iQIYIMedia_[0-9]+\.dmg' <<<"$html" | head -1)

if [ -z "$new_url" ]; then
  echo "failed to parse dmg url from page" >&2
  echo "possible page structure change, check: $PAGE" >&2
  exit 1
fi

cur_ver=$(grep -m1 'version "' "$CASK" | sed -E 's/.*version "([^"]+)".*/\1/')
cur_url=$(grep -m1 'url "' "$CASK" | sed -E 's/.*url "([^"]+)".*/\1/')

# dmg URL 没变 → 跳过下载，上游未更新
if [ "$cur_url" = "$new_url" ]; then
  echo "already up-to-date ($cur_ver, url unchanged)"
  exit 0
fi

# dmg URL 变了 → 下载、提取真实版本、计算 sha256
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
curl -fsSL -o "$tmp/app.dmg" "$new_url"

# 挂载 dmg，从 Info.plist 读取真实版本号（不信任页面文案）
vol_path=$(hdiutil attach "$tmp/app.dmg" -nobrowse -readonly -mountrandom "$tmp" | awk 'END{print $NF}')
app_path=$(echo "$vol_path"/*.app | head -1)
new_ver=$(plutil -p "$app_path/Contents/Info.plist" 2>/dev/null | grep CFBundleShortVersionString | sed -E 's/.*"([^"]+)".*/\1/')
hdiutil detach "$vol_path" -force >/dev/null 2>&1

if [ -z "$new_ver" ]; then
  echo "failed to extract version from app bundle" >&2
  exit 1
fi

sha=$(shasum -a 256 "$tmp/app.dmg" | cut -d' ' -f1)

if [ "$cur_ver" = "$new_ver" ]; then
  echo "dmg url changed but version unchanged ($cur_ver), updating sha256/url only"
fi

sed -i.bak -E \
  -e "s|version \"[^\"]+\"|version \"$new_ver\"|" \
  -e "s|sha256 \"[^\"]+\"|sha256 \"$sha\"|" \
  -e "s|url \"https://static-d\.iqiyi\.com[^\"]+\"|url \"$new_url\"|" \
  "$CASK" && rm -f "$CASK.bak"

echo "bumped $cur_ver -> $new_ver"
echo "url=$new_url"
echo "sha256=$sha"
