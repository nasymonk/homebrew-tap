#!/usr/bin/env bash
# Bump the qoder cask by detecting OSS ETag changes and extracting version from DMG.
# 上游只有无版本号 latest 直链，以 HEAD 请求 OSS ETag 检测变更；
# 版本号取自 dmg 内 App Bundle 的 CFBundleShortVersionString（同 iqiyi 手法）。
set -euo pipefail

CASK="${1:-Casks/qoder.rb}"

ARM_URL="https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg"
INTEL_URL="https://download.qoder.com/release/latest/Qoder-darwin-x64.dmg"

# --- 1. HEAD 双架构取 ETag ---
arm_etag=$(curl -sI --max-time 30 "$ARM_URL" | grep -i '^etag:' | tr -d '\r"' | sed 's/^[Ee][Tt]ag: *//')
intel_etag=$(curl -sI --max-time 30 "$INTEL_URL" | grep -i '^etag:' | tr -d '\r"' | sed 's/^[Ee][Tt]ag: *//')

if [ -z "$arm_etag" ] || [ -z "$intel_etag" ]; then
  echo "failed to fetch ETag from upstream (arm='${arm_etag:-}' intel='${intel_etag:-}')" >&2
  exit 1
fi

# --- 2. 读取上一次 ETag ---
prev_etag_line=$(grep '^  # upstream-etag ' "$CASK" 2>/dev/null || true)
prev_arm=$(echo "$prev_etag_line" | grep -o 'arm=[^ ]*' | cut -d= -f2)
prev_intel=$(echo "$prev_etag_line" | grep -o 'x64=[^ ]*' | cut -d= -f2)

# --- 3. 均未变 → 跳过 ---
if [ "$arm_etag" = "$prev_arm" ] && [ "$intel_etag" = "$prev_intel" ]; then
  echo "already up-to-date (ETags unchanged)"
  exit 0
fi

# --- 4. 下载双架构 dmg、提取版本、计算 sha ---
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL --max-time 300 -o "$tmp/arm.dmg" "$ARM_URL"
curl -fsSL --max-time 300 -o "$tmp/intel.dmg" "$INTEL_URL"

# 挂载 ARM dmg 提取版本号
vol_path=$(hdiutil attach "$tmp/arm.dmg" -nobrowse -readonly -mountrandom "$tmp" | awk 'END{print $NF}')
app_path=$(echo "$vol_path"/*.app | head -1)
new_ver=$(plutil -p "$app_path/Contents/Info.plist" 2>/dev/null | grep CFBundleShortVersionString | sed -E 's/.*"([^"]+)".*/\1/')
hdiutil detach "$vol_path" -force >/dev/null 2>&1

if [ -z "$new_ver" ]; then
  echo "failed to extract version from app bundle ($app_path)" >&2
  exit 1
fi

arm_sha=$(shasum -a 256 "$tmp/arm.dmg" | cut -d' ' -f1)
intel_sha=$(shasum -a 256 "$tmp/intel.dmg" | cut -d' ' -f1)

cur_ver=$(grep -m1 'version "' "$CASK" | sed -E 's/.*version "([^"]+)".*/\1/')

# --- 5. 改写 cask ---

# version
sed -i.bak -E "s/version \"[^\"]+\"/version \"$new_ver\"/" "$CASK" && rm -f "$CASK.bak"

# sha256: 分 on_arm / on_intel 块替换
awk -v arm="$arm_sha" -v intel="$intel_sha" '
  /on_arm do/   { blk="arm" }
  /on_intel do/ { blk="intel" }
  /sha256 "/ {
    if (blk=="arm")   { sub(/sha256 "[^"]+"/, "sha256 \"" arm "\""); blk="" }
    else if (blk=="intel") { sub(/sha256 "[^"]+"/, "sha256 \"" intel "\""); blk="" }
  }
  { print }
' "$CASK" > "$CASK.tmp" && mv "$CASK.tmp" "$CASK"

# upstream-etag 注释行
if grep -q '^  # upstream-etag ' "$CASK"; then
  sed -i.bak -E "s/^  # upstream-etag .*/  # upstream-etag arm=${arm_etag} x64=${intel_etag}/" "$CASK" && rm -f "$CASK.bak"
else
  # 兼容：首次运行 cask 中无 etag 行时插入
  awk -v arm="$arm_etag" -v intel="$intel_etag" '
    /^  version "/ && !done {
      print
      print "  # upstream-etag arm=" arm " x64=" intel
      done=1
      next
    }
    { print }
  ' "$CASK" > "$CASK.tmp" && mv "$CASK.tmp" "$CASK"
fi

echo "bumped $cur_ver -> $new_ver"
echo "arm_sha=$arm_sha"
echo "intel_sha=$intel_sha"
echo "arm_etag=$arm_etag"
echo "intel_etag=$intel_etag"
