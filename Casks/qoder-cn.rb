cask "qoder-cn" do
  version "1.8.0"

  # 上游只提供无版本号的 lastest 直链，URL 永远不变；
  # 版本/sha256 由 scripts/bump-qoder-cn.sh 依 OSS ETag 变更检测后改写。
  # upstream-etag arm=905A4980D1E328854487FCEFCC7C34F3 x64=3741BF646995BE8A92592DF7E3A976CA
  on_arm do
    sha256 "cb40468ba6db4597618911a01a9e67763bb0786f46e8b832765d7f670db6567c"
    url "https://ide.qoder.com.cn/qoder/release/lastest/QoderCN-darwin-arm64.dmg"
  end
  on_intel do
    sha256 "ebb422e5758639ddc0d8aff074c620da8806ad190066990c1da7a4e936cf8663"
    url "https://ide.qoder.com.cn/qoder/release/lastest/QoderCN-darwin-x64.dmg"
  end

  name "Qoder CN"
  desc "Agentic coding IDE from Alibaba (China edition)"
  homepage "https://qoder.com.cn/"

  livecheck do
    skip "上游仅提供无版本号 lastest 直链，无公开版本源"
  end

  # Qoder CN 为 VS Code fork，内置自更新
  auto_updates true

  app "Qoder CN.app"

  zap trash: [
    "~/Library/Application Support/Qoder CN",
    "~/Library/Caches/com.aliyun.lingma.ide",
    "~/Library/Caches/Qoder CN",
    "~/Library/Preferences/com.aliyun.lingma.ide.plist",
    "~/Library/Saved Application State/com.aliyun.lingma.ide.savedState",
  ]
end
