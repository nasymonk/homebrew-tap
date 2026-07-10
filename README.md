# nasymonk/homebrew-tap

[![autobump](https://github.com/nasymonk/homebrew-tap/actions/workflows/autobump.yml/badge.svg)](https://github.com/nasymonk/homebrew-tap/actions/workflows/autobump.yml)

社区维护的 Homebrew tap -- 收录官方 [homebrew-cask](https://github.com/Homebrew/homebrew-cask) 未收录、且上游作者未自建 tap 的 macOS 软件。版本由 GitHub Actions **每 5 小时**自动检测并更新，无需手动维护。

## 快速开始

```bash
# 1. 添加 tap
brew tap nasymonk/tap

# 2. 信任 tap（Homebrew 4.x+ 首次使用第三方 tap 时需要）
brew trust nasymonk/tap

# 3. 安装软件
brew install --cask <cask-name>
```

<details>
<summary>更多操作</summary>

```bash
# 升级到最新版
brew update && brew upgrade --cask <cask-name>

# 卸载
brew uninstall --cask <cask-name>

# 卸载并清除所有配置文件
brew uninstall --cask --zap <cask-name>

# 强制接管已有 App（/Applications 里已有同名 App 时需要）
brew install --cask --force <cask-name>
```

</details>

## 现有软件

| Cask | 说明 | 自动更新来源 | 上游 |
|------|------|-------------|------|
| `aio-coding-hub` | 本地 AI 网关，统一代理多个 coding CLI | GitHub Releases API | [dyndynjyxa/aio-coding-hub](https://github.com/dyndynjyxa/aio-coding-hub) |
| `buhocleaner` | Mac 清理 / 优化工具 | Sparkle appcast (XML) | [drbuho.com](https://www.drbuho.com/buhocleaner) |
| `iqiyi` | 爱奇艺视频播放器 | 官网下载页 HTML 解析 | [app.iqiyi.com](https://app.iqiyi.com/mac/player/index.html) |

## 自动更新机制

`.github/workflows/autobump.yml` 每 5 小时（UTC :17）自动运行，依次为每个 cask 执行对应的 bump 脚本：

> 查上游最新版本 -> 下载安装包并计算 SHA256 -> 更新 cask 文件 -> 有变化时自动 commit & push

用户侧只需 `brew update && brew upgrade --cask <name>` 即可获取最新版，完全不耗本地资源。也可在 [Actions](https://github.com/nasymonk/homebrew-tap/actions/workflows/autobump.yml) 页面手动触发。

> **注意**：GitHub 规定公开仓库连续 60 天无提交会停用定时任务。任一软件更新触发提交即自动续期；若被停用，去 Actions 页面点击 "Run workflow" 重新启用。

## 贡献

欢迎通过以下方式参与：

- [提交软件请求](https://github.com/nasymonk/homebrew-tap/issues/new?template=software_request.yml) -- 推荐你希望收录的 macOS 软件
- [报告问题](https://github.com/nasymonk/homebrew-tap/issues/new?template=bug_report.yml) -- 反馈 cask 安装失败、版本过旧等问题
- 提交 Pull Request -- 直接添加或修复 cask

## License

MIT
