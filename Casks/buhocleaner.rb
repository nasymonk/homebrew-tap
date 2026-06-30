cask "buhocleaner" do
  version "1.16.2"
  sha256 "ecfb2f81bf2732663a422981714ab6b343418bd2748081cc57f2b466c4af2d0e"

  # dmg 文件名含构建号 (buhocleaner_b<build>.dmg),与版本号无关。
  # 版本/链接/sha 由 scripts/bump-buhocleaner.sh 解析 Sparkle appcast 改写。
  url "https://drbuho.net/buhocleaner/buhocleaner_b256.dmg"
  name "BuhoCleaner"
  desc "Mac cleaner and optimizer"
  homepage "https://www.drbuho.com/buhocleaner"

  livecheck do
    url "https://www.drbuho.com/buho-public-files/buhocleaner/appcast.xml"
    strategy :sparkle
  end

  app "BuhoCleaner.app"

  zap trash: [
    "~/Library/Application Support/com.drbuho.BuhoCleaner",
    "~/Library/Caches/com.drbuho.BuhoCleaner",
    "~/Library/HTTPStorages/com.drbuho.BuhoCleaner",
    "~/Library/Preferences/com.drbuho.BuhoCleaner.plist",
    "~/Library/Saved Application State/com.drbuho.BuhoCleaner.savedState",
  ]
end
