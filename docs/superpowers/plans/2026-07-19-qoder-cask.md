# Qoder IDE Cask 接入实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Qoder AI 编程 IDE macOS 桌面端接入 nasymonk/homebrew-tap，含 cask、自动 bump 脚本、CI 与 README。

**Architecture:** 双架构 fixed-latest-URL cask（`on_arm`/`on_intel`），真实版本号取自 dmg 内 Info.plist，OSS ETag 做低成本变更检测，bump 脚本随 autobump workflow 每 5 小时自动运行。CI runner 从 ubuntu 迁移至 macos（修复 iqiyi 的 hdiutil 潜在故障 + qoder 新脚本同依赖）。

**Tech Stack:** Bash（bump 脚本）、Ruby DSL（cask 定义）、GitHub Actions YAML（CI）、Homebrew cask DSL。

## 全局约束

- tap 仓库路径：`/opt/homebrew/Library/Taps/nasymonk/homebrew-tap`
- commit message 用英文前缀（`feat:`、`fix:`）后接中文
- 新增脚本必须可执行（`chmod +x scripts/*.sh`）
- macOS runner 已验证公开仓库免费可用
- Qoder 上游 URL 固定 `https://download.qoder.com/release/latest/Qoder-darwin-{arm64,x64}.dmg`

---

### Task 1: 发现阶段 —— 下载 DMG 并提取元数据

**Files:**
- No files created/modified — 此任务仅做数据收集

**Interfaces:**
- Produces: 变量 `VERSION`、`ARM_SHA`、`INTEL_SHA`、`APP_NAME`、`BUNDLE_ID`、`ARM_ETAG`、`INTEL_ETAG`，写入 `/tmp/qoder_discovery.env` 供 Task 2 引用

从上游 latest URL 下载双架构 DMG，挂载 ARM DMG 提取应用名、版本号和 bundle ID，计算双 sha256，记录当前 OSS ETag。

- [ ] **Step 1: 下载 ARM64 DMG**

```bash
cd /tmp
curl -fsSL --max-time 300 \
  -o qoder-arm64.dmg \
  'https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg'
```

预期：下载完成，文件约 244MB。`ls -lh qoder-arm64.dmg` 确认存在。

- [ ] **Step 2: 下载 Intel DMG**

```bash
curl -fsSL --max-time 300 \
  -o qoder-x64.dmg \
  'https://download.qoder.com/release/latest/Qoder-darwin-x64.dmg'
```

预期：下载完成，文件约 244MB。

- [ ] **Step 3: 获取 OSS ETag（变更检测基线）**

```bash
ARM_ETAG=$(curl -sI --max-time 30 \
  'https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg' \
  | grep -i '^etag:' | tr -d '\r' | sed 's/^[Ee][Tt]ag: *//')
INTEL_ETAG=$(curl -sI --max-time 30 \
  'https://download.qoder.com/release/latest/Qoder-darwin-x64.dmg' \
  | grep -i '^etag:' | tr -d '\r' | sed 's/^[Ee][Tt]ag: *//')
echo "ARM_ETAG=$ARM_ETAG"
echo "INTEL_ETAG=$INTEL_ETAG"
```

预期：两个 ETag 均有值（形如 `"631EDFCEB439AABFA0D60E963E68C4CB"`）。

- [ ] **Step 4: 挂载 ARM DMG，提取应用名和 bundle ID**

```bash
TMPMNT=$(mktemp -d)
hdiutil attach qoder-arm64.dmg -nobrowse -readonly -mountrandom "$TMPMNT"
APP_PATH=$(echo "$TMPMNT"/*.app | head -1)
APP_NAME=$(basename "$APP_PATH" .app)
echo "APP_NAME=$APP_NAME"

BUNDLE_ID=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleIdentifier | sed -E 's/.*"([^"]+)".*/\1/')
echo "BUNDLE_ID=$BUNDLE_ID"

VERSION=$(plutil -p "$APP_PATH/Contents/Info.plist" | grep CFBundleShortVersionString | sed -E 's/.*"([^"]+)".*/\1/')
echo "VERSION=$VERSION"

VOL_DIR=$(df "$APP_PATH" | tail -1 | awk '{print $NF}')
hdiutil detach "$VOL_DIR" -force
```

预期：`APP_NAME`（如 `Qoder`）、`BUNDLE_ID`（如 `com.alibaba.qoder`）、`VERSION`（如 `1.106.0`）均非空。

- [ ] **Step 5: 计算双架构 SHA256**

```bash
ARM_SHA=$(shasum -a 256 qoder-arm64.dmg | cut -d' ' -f1)
INTEL_SHA=$(shasum -a 256 qoder-x64.dmg | cut -d' ' -f1)
echo "ARM_SHA=$ARM_SHA"
echo "INTEL_SHA=$INTEL_SHA"
```

预期：两个 64 字符 hex。

- [ ] **Step 6: 保存全部发现值**

```bash
cat > /tmp/qoder_discovery.env <<EOF
VERSION=$VERSION
ARM_SHA=$ARM_SHA
INTEL_SHA=$INTEL_SHA
APP_NAME=$APP_NAME
BUNDLE_ID=$BUNDLE_ID
ARM_ETAG=$ARM_ETAG
INTEL_ETAG=$INTEL_ETAG
EOF
echo "=== Discovery complete ==="
cat /tmp/qoder_discovery.env
```

预期：所有变量已填入，无空值。

---

### Task 2: 创建 `Casks/qoder.rb`

**Files:**
- Create: `Casks/qoder.rb`

**Interfaces:**
- Consumes: Task 1 的环境文件 `/tmp/qoder_discovery.env` 中的 `VERSION`、`ARM_SHA`、`INTEL_SHA`、`APP_NAME`、`BUNDLE_ID`、`ARM_ETAG`、`INTEL_ETAG`

- [ ] **Step 1: 加载发现值并写入 cask 文件**

```bash
source /tmp/qoder_discovery.env
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap

cat > Casks/qoder.rb << EOF
cask "qoder" do
  version "${VERSION}"

  # 上游只提供无版本号的 latest 直链，URL 永远不变；
  # 版本/sha256 由 scripts/bump-qoder.sh 依 OSS ETag 变更检测后改写。
  # upstream-etag arm=${ARM_ETAG} x64=${INTEL_ETAG}
  on_arm do
    sha256 "${ARM_SHA}"
    url "https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg"
  end
  on_intel do
    sha256 "${INTEL_SHA}"
    url "https://download.qoder.com/release/latest/Qoder-darwin-x64.dmg"
  end

  name "Qoder"
  desc "Agentic coding IDE from Alibaba"
  homepage "https://qoder.com/"

  livecheck do
    skip "上游仅提供无版本号 latest 直链，无公开版本源"
  end

  # Qoder 为 VS Code fork，内置自更新；安装后若实际未发现自更新机制则移除本行
  auto_updates true

  app "${APP_NAME}.app"

  # bundle ID 按实际安装后目录为准，以下为推测值（Task 6 安装后验证修正）
  zap trash: [
    "~/Library/Application Support/${APP_NAME}",
    "~/Library/Caches/${APP_NAME}",
    "~/Library/Preferences/${BUNDLE_ID}.plist",
    "~/Library/Saved Application State/${BUNDLE_ID}.savedState",
  ]
end
EOF
```

- [ ] **Step 2: 验证 Ruby 语法**

```bash
ruby -c Casks/qoder.rb
```

预期：`Syntax OK`。

- [ ] **Step 3: 提交**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
git add Casks/qoder.rb
git commit -m "feat: 新增 qoder cask（OSS ETag 自动检测）"
```

---

### Task 3: 创建 `scripts/bump-qoder.sh`

**Files:**
- Create: `scripts/bump-qoder.sh`

- [ ] **Step 1: 写入完整的 bump 脚本**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap

cat > scripts/bump-qoder.sh << 'SCRIPT'
#!/usr/bin/env bash
# Bump the qoder cask by detecting OSS ETag changes and extracting version from DMG.
# 上游只有无版本号 latest 直链，以 HEAD 请求 OSS ETag 检测变更；
# 版本号取自 dmg 内 App Bundle 的 CFBundleShortVersionString（同 iqiyi 手法）。
set -euo pipefail

CASK="${1:-Casks/qoder.rb}"

ARM_URL="https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg"
INTEL_URL="https://download.qoder.com/release/latest/Qoder-darwin-x64.dmg"

# --- 1. HEAD 双架构取 ETag ---
arm_etag=$(curl -sI --max-time 30 "$ARM_URL" | grep -i '^etag:' | tr -d '\r' | sed 's/^[Ee][Tt]ag: *//')
intel_etag=$(curl -sI --max-time 30 "$INTEL_URL" | grep -i '^etag:' | tr -d '\r' | sed 's/^[Ee][Tt]ag: *//')

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
SCRIPT
```

- [ ] **Step 2: 加可执行权限并语法验证**

```bash
chmod +x scripts/bump-qoder.sh
bash -n scripts/bump-qoder.sh
```

预期：`bash -n` 无输出（语法正确）。

- [ ] **Step 3: 提交**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
git add scripts/bump-qoder.sh
git commit -m "feat: 新增 qoder bump 脚本（OSS ETag 变更检测）"
```

---

### Task 4: 更新 `autobump.yml`（切 macos-latest + 加 qoder 步骤）

**Files:**
- Modify: `.github/workflows/autobump.yml`

- [ ] **Step 1: 读入当前文件并完整替换**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap

cat > .github/workflows/autobump.yml << 'YAML'
name: autobump

on:
  schedule:
    - cron: "17 */5 * * *"   # every 5 hours, at :17 (UTC)
  workflow_dispatch:        # manual trigger from the Actions tab

permissions:
  contents: write

jobs:
  bump:
    runs-on: macos-latest   # iqiyi/qoder bump 脚本依赖 hdiutil/plutil
    steps:
      - uses: actions/checkout@v4

      - name: Bump aio-coding-hub
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          bash scripts/bump-cask.sh \
            Casks/aio-coding-hub.rb \
            dyndynjyxa/aio-coding-hub \
            aio-coding-hub-macos-arm.zip \
            aio-coding-hub-macos-intel.zip \
            aio-coding-hub-v

      - name: Bump iqiyi
        run: bash scripts/bump-iqiyi.sh Casks/iqiyi.rb

      - name: Bump qoder
        run: bash scripts/bump-qoder.sh Casks/qoder.rb

      - name: Bump buhocleaner
        run: bash scripts/bump-buhocleaner.sh Casks/buhocleaner.rb

      - name: Commit & push if changed
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            git config user.name  "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git commit -am "autobump casks to latest"
            git push
          else
            echo "no changes to commit"
          fi
YAML
```

关键改动：
- `runs-on: ubuntu-latest` → `macos-latest`
- 新增 `Bump qoder` step（放 iqiyi 与 buhocleaner 之间）

- [ ] **Step 2: 提交**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
git add .github/workflows/autobump.yml
git commit -m "fix: autobump 迁移 macOS runner，新增 qoder 步骤"
```

---

### Task 5: 更新 `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 在「现有软件」表格中插入 qoder 行**

在 `README.md` 表格中 `iqiyi` 行后面插入：

```markdown
| `qoder` | Qoder AI 编程 IDE | OSS ETag 变更检测 + dmg 内版本号 | [qoder.com](https://qoder.com/) |
```

具体修改：编辑 `/opt/homebrew/Library/Taps/nasymonk/homebrew-tap/README.md`，找到 `| \`iqiyi\`` 行，在其后面加入上述行。

- [ ] **Step 2: 提交**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
git add README.md
git commit -m "docs: README 新增 qoder cask"
```

---

### Task 6: 本地验证

**Files:**
- Potentially modify: `Casks/qoder.rb`（zap 路径修正）

- [ ] **Step 1: brew audit**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
brew audit --cask Casks/qoder.rb
```

预期：通过，无 error 或 warning。

- [ ] **Step 2: brew install**

```bash
brew install --cask Casks/qoder.rb
```

预期：sha256 校验通过，app 安装到 `/Applications/`。

```bash
source /tmp/qoder_discovery.env
open "/Applications/${APP_NAME}.app"
```

确认 app 无崩溃、正常启动（等待 3-5 秒）。由于已设 `auto_updates true`，app 可能在启动时触发自更新——属预期行为。

- [ ] **Step 3: 验证并修正 zap 路径**

```bash
source /tmp/qoder_discovery.env
echo "=== Checking Application Support ==="
ls -d ~/Library/Application\ Support/${APP_NAME}/ 2>/dev/null || echo "NOT FOUND -- check:"
ls ~/Library/Application\ Support/ | grep -i qoder || echo "(no qoder match)"

echo "=== Checking Preferences ==="
ls ~/Library/Preferences/${BUNDLE_ID}.plist 2>/dev/null || echo "NOT FOUND -- check:"
ls ~/Library/Preferences/ | grep -i qoder || echo "(no qoder match)"

echo "=== Checking Caches ==="
ls -d ~/Library/Caches/${APP_NAME}/ 2>/dev/null || echo "NOT FOUND -- check:"
ls ~/Library/Caches/ | grep -i qoder || echo "(no qoder match)"

echo "=== Checking Saved Application State ==="
ls -d ~/Library/Saved\ Application\ State/${BUNDLE_ID}.savedState/ 2>/dev/null || echo "NOT FOUND"
```

若任一路径不匹配：
1. 用 `ls` 输出找出实际路径名
2. 编辑 `Casks/qoder.rb` 修正 `zap trash` 数组中对应的字符串
3. 提交修正：`git add Casks/qoder.rb && git commit -m "fix: 修正 qoder zap 路径（安装后实测）"`

若全部匹配则无需修改。

- [ ] **Step 4: bump 脚本空跑验证**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
bash scripts/bump-qoder.sh Casks/qoder.rb
```

预期输出：`already up-to-date (ETags unchanged)`。

- [ ] **Step 5: 最终检查**

```bash
cd /opt/homebrew/Library/Taps/nasymonk/homebrew-tap
git status
git log --oneline -6
```

确认所有变更已提交，提交历史清晰。
