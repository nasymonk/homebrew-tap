# Qoder IDE Cask 接入 nasymonk/homebrew-tap 设计

日期：2026-07-19

## 背景

Qoder（阿里出品 AI 编程 IDE，VS Code fork）macOS 桌面端在官方 homebrew-cask 与上游官方 tap（`QoderAI/homebrew-qoder`，仅含 CLI）中均无收录，符合 nasymonk/homebrew-tap 的 "官方未收录且上游无自建 tap" 标准。

上游分发方式：阿里云 OSS 直连 latest 地址，不提供版本号重定向、不提供公开 version.json / appcast。

## 设计决策

### 版本策略：真实版本号 + OSS ETag 变更检测（方案 A）

| 维度 | 选择 | 理由 |
|------|------|------|
| cask version | dmg 内 `CFBundleShortVersionString`（真实版本） | `brew upgrade` 语义正常，用户可见版本 |
| 变更检测 | HEAD 请求双架构 OSS `ETag` 响应头 | 低成本（两个 HEAD），无需下载 244MB |
| 版本提取 | `hdiutil attach` + `plutil -p .../Info.plist` | 复用 iqiyi cask 成熟手法 |
| livecheck | `skip` | 上游无公开可查询版本源，声明而非凑假 |
| URL | 固定 `release/latest/Qoder-darwin-{arm64,x64}.dmg` | 上游只提供 latest，无版本号 URL |

### ETag 状态存储

存入 cask 文件注释行（自包含，无需额外状态文件，随 autobump 提交）：

```ruby
# upstream-etag arm=<etag> x64=<etag>
```

## 实现清单

### 1. `Casks/qoder.rb`

- `version`：dmg App Bundle 真实版本号，bump 脚本维护
- `on_arm` / `on_intel`：各自配有 `sha256` 和固定 latest URL
- `name "Qoder"`，`desc "Agentic coding IDE from Alibaba"`
- `homepage "https://qoder.com/"`
- `app "Qoder.app"`（以安装后实际 .app 名为准）
- `zap trash`：安装后实测确定具体路径与 bundle id
- 若 Qoder 内置自更新（VS Code fork 常见行为），加 `auto_updates true`

### 2. `scripts/bump-qoder.sh`

```
HEAD arm64 → ETag_arm
HEAD x64   → ETag_x64
  如果与 cask 注释中上一次 ETag 均一致 → "already up-to-date" 退出

任一 ETag 变化 → 下载两个 dmg（确保 version + sha 成对一致）
  ↓
挂载 ARM dmg（hdiutil mountrandom）
  ↓
plutil Info.plist → CFBundleShortVersionString = new_version
  ↓
卸载 DMG（hdiutil detach）
  ↓
计算双 sha256（shasum -a 256）
  ↓
改写 cask 文件（sed + awk）：
  - version → new_version
  - arm sha256  → arm_sha
  - intel sha256 → intel_sha
  - upstream-etag 注释行 → 新 ETag
```

错误处理：
- HEAD 失败 → 报错退出，CI 可见
- 版本提取失败 → 报错退出
- "ETag 变但版本没变"（上游重传同版本） → 仅更新 sha + ETag，不更新 version

### 3. `autobump.yml` 修改

**⚠️ 关键修复：`runs-on` 从 `ubuntu-latest` 改为 `macos-latest`**

- `bump-iqiyi.sh` 已依赖 `hdiutil` / `plutil`（macOS 专有），当前跑在 Linux 上没炸只是因为爱奇艺没发新版一直走 URL 不变早退分支
- `bump-qoder.sh` 同样依赖 hdiutil，必须 macOS runner
- 公开仓库 macOS runner 免费，无额外成本

增加 "Bump qoder" 步骤，放在 "Bump iqiyi" 之后。

### 4. README 更新

"现有软件" 表加一行：

| Cask | 说明 | 自动更新来源 | 上游 |
|------|------|-------------|------|
| `qoder` | Qoder AI 编程 IDE | OSS ETag 变更检测 + dmg 内版本号 | [qoder.com](https://qoder.com/) |

## 验收标准

1. `brew audit --cask qoder` 通过（在 tap 目录运行）
2. 本机 `brew install --cask qoder` 成功，app 可正常启动
3. `scripts/bump-qoder.sh` 空跑输出 `already up-to-date`
4. CI（macos-latest）上 autobump 工作流通过

## 已知风险

- **sha 在更新窗口内不匹配**：上游更新 latest 到 autobump 脚本触发间（最长 5 小时），`brew install` 的 sha 校验会失败。tap 既有 cask（iqiyi、buhocleaner）已接受此风险，用户侧重试一次或等一次性即可。
- **单次下载 ~500 MB**：双架构 dmg 各约 ~244 MB，bump 脚本每次检测到更新均下载两份。CI macOS runner 有充足磁盘空间，无瓶颈。
- **Qoder 官方将来推出 IDE cask**：若后续 `QoderAI/homebrew-qoder` 加入 IDE，届时关闭本 tap 的 qoder cask 或改为 alias，README 加入相应指引即可。
