cask "qoder" do
  version "1.18.0"

  # 上游只提供无版本号的 latest 直链，URL 永远不变；
  # 版本/sha256 由 scripts/bump-qoder.sh 依 OSS ETag 变更检测后改写。
  # upstream-etag arm=D907125FC2E157731C67A7F105B08760 x64=10648C7BCA7755BF6D62B63E1781F523
  on_arm do
    sha256 "e150cda6a1d8f39e96eb8ddb29abdfd292390e701892c4a1f54dab6057d21e6d"
    url "https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg"
  end
  on_intel do
    sha256 "f21ceea92587fb31523f56d83483c9275d16c943dacba2e0669888feae338244"
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

  app "Qoder.app"

  # bundle ID 按实际安装后目录为准，以下为推测值（Task 6 安装后验证修正）
  zap trash: [
    "~/Library/Application Support/Qoder",
    "~/Library/Caches/Qoder",
    "~/Library/Preferences/com.qoder.ide.plist",
    "~/Library/Saved Application State/com.qoder.ide.savedState",
  ]
end
