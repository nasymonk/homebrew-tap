# nasymonk/homebrew-tap

个人 Homebrew tap —— 收录官方未收录、且作者未自建 tap 的软件。

## 使用

```bash
brew tap nasymonk/tap
brew install --cask aio-coding-hub      # 无重名时可省略前缀
# 或显式: brew install --cask nasymonk/tap/aio-coding-hub
```

升级:

```bash
brew update && brew upgrade --cask aio-coding-hub
```

## 自动更新机制

`.github/workflows/autobump.yml` 每天定时运行 `scripts/bump-cask.sh`:
查上游最新 release → 下载安装包算 sha256 → 改写 cask 的 `version`/`sha256` → 自动提交。

之后用户 `brew update`(会自动拉取本 tap 最新内容)+ `brew upgrade` 即可装到新版。

## 新增一个软件

1. 在 `Casks/` 下加一个 `<name>.rb`(GitHub release 类型可参考 `aio-coding-hub.rb`)。
2. 在 `autobump.yml` 里仿照现有 step 加一段 bump 调用,传入:
   `cask 文件 / owner/repo / arm 资源名 / intel 资源名 / tag 前缀`。

## 现有软件

| Cask | 说明 | 上游 |
|------|------|------|
| `aio-coding-hub` | 本地 AI 网关,统一代理多个 coding CLI | [dyndynjyxa/aio-coding-hub](https://github.com/dyndynjyxa/aio-coding-hub) |
