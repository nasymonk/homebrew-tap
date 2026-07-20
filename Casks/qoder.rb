cask "qoder" do
  version "1.16.1"

  # 上游只提供无版本号的 latest 直链，URL 永远不变；
  # 版本/sha256 由 scripts/bump-qoder.sh 依 OSS ETag 变更检测后改写。
  # upstream-etag arm=2FE169B9F573B15D76C0681BB0F72620 x64=53EEFD91AE77CE43807FE555D60E1D93
  on_arm do
    sha256 "600a175f154dc81f783392b6f3994ea26ce0cd25bdbbfeb9ceaf70a6abf5f7de"
    url "https://download.qoder.com/release/latest/Qoder-darwin-arm64.dmg"
  end
  on_intel do
    sha256 "6b1855351113bb4d98a8e7108a5628a845c4ae0a76e967d2d2dd6e128c0127c9"
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
