# nasymonk/homebrew-tap

个人 Homebrew tap —— 收录官方 homebrew-cask 未收录、且作者未自建 tap 的软件。

## 使用

```bash
brew tap nasymonk/tap
brew trust nasymonk/tap                  # brew 6.x 第三方 tap 需先信任
brew install --cask <name>               # 无重名时可省略前缀
# 或显式: brew install --cask nasymonk/tap/<name>
```

升级 / 卸载:

```bash
brew update && brew upgrade --cask <name>
brew uninstall --cask <name>             # 加 --zap 连配置一起清掉
```

## 现有软件

| Cask | 说明 | 版本来源 | 上游 |
|------|------|---------|------|
| `aio-coding-hub` | 本地 AI 网关,统一代理多个 coding CLI | GitHub Releases API | [dyndynjyxa/aio-coding-hub](https://github.com/dyndynjyxa/aio-coding-hub) |
| `iqiyi` | 爱奇艺视频播放器 | 抓官网下载页 HTML | [app.iqiyi.com](https://app.iqiyi.com/mac/player/index.html) |
| `buhocleaner` | Mac 清理 / 优化工具 | Sparkle appcast (XML) | [drbuho.com](https://www.drbuho.com/buhocleaner) |

## 自动更新机制

`.github/workflows/autobump.yml` **每 5 小时**(cron `17 */5 * * *`)在 GitHub 云端运行,
依次为每个软件跑对应的 bump 脚本:查上游最新版 → 下载安装包算 sha256 →
改写 cask 的 `version`/`url`/`sha256` → 有变化就自动 commit & push。

之后 `brew update`(会自动拉取本 tap 最新内容)+ `brew upgrade` 即可装到新版。
完全不耗本地资源;也可在 Actions 页面手动 "Run workflow"。

> 注意:GitHub 规定公开仓库连续 60 天无提交会停用定时任务。
> 任一软件更新触发提交即自动续期;若真被停用,去 Actions 页面点一下重新启用。

### 三种 bump 脚本

| 脚本 | 适用场景 | 版本来源 |
|------|---------|---------|
| `scripts/bump-cask.sh` | 上游在 **GitHub Releases** 发版 | Releases API,按 tag 拼 URL |
| `scripts/bump-iqiyi.sh` | 无 API,**官网下载页**含直链+版本 | 解析页面 HTML |
| `scripts/bump-buhocleaner.sh` | 有 **Sparkle appcast** | 解析 appcast.xml(最规范) |

## 新增一个软件

1. 在 `Casks/` 下加一个 `<name>.rb`(参考同类现有 cask)。
2. 选/写一个 bump 脚本,在 `autobump.yml` 里加一段 step 调用它。
   - **优先找 Sparkle appcast**(Info.plist 里的 `SUFeedURL`)→ 仿 `bump-buhocleaner.sh`,最稳。
   - 有 GitHub Releases → 用 `bump-cask.sh`,传 `cask文件 / owner/repo / arm资源名 / intel资源名 / tag前缀`。
   - 只有官网下载页 → 仿 `bump-iqiyi.sh` 解析 HTML。
3. 本地验证:`bash scripts/<bump>.sh Casks/<name>.rb` 应报 `already up-to-date`;
   `brew livecheck --cask <name>` 能查到版本。
4. commit & push,然后 `brew install --cask <name>`。

> Tip:若 `/Applications` 已有手动装的同名 App,`brew install` 会拒绝覆盖,
> 加 `--force` 接管;若旧副本是 root 所有,需先 `sudo rm -rf` 删除。
