cask "iqiyi" do
  version "17.6.5"
  sha256 "5a59b71f7d24894b39c319d6d93a4c06147ef5eef8aaad707775177036c210f4"

  # URL 文件名是内部构建号 (iQIYIMedia_NNN.dmg),与版本号无关,
  # 故 url 整条硬编码;升级由 scripts/bump-iqiyi.sh 抓下载页改写。
  url "https://static-d.iqiyi.com/ext/common/iQIYIMedia_271.dmg"
  name "爱奇艺"
  name "iQIYI"
  desc "Video streaming player"
  homepage "https://app.iqiyi.com/mac/player/index.html"

  livecheck do
    url "https://app.iqiyi.com/mac/player/index.html"
    regex(/v?(\d+(?:\.\d+)+)/i)
    strategy :page_match
  end

  app "爱奇艺.app"

  zap trash: [
    "~/Library/Application Support/com.iqiyi.player",
    "~/Library/Caches/com.iqiyi.player",
    "~/Library/Preferences/com.iqiyi.player.plist",
    "~/Library/Saved Application State/com.iqiyi.player.savedState",
  ]
end
