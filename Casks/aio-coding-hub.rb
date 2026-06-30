cask "aio-coding-hub" do
  version "0.60.2"

  on_arm do
    sha256 "b992675229c33270a744a0bc5b86c0dd8516c0dcdb5046c4ec861d4a00abf804"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-arm.zip"
  end
  on_intel do
    sha256 "a4965518b4dc2fa34861557739189ee95ea079c5488bd4d883bff8c5096f907d"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-intel.zip"
  end

  name "AIO Coding Hub"
  desc "Local AI gateway for routing multiple coding CLIs"
  homepage "https://github.com/dyndynjyxa/aio-coding-hub"

  livecheck do
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases"
    regex(/aio-coding-hub-v(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  app "AIO Coding Hub.app"

  zap trash: [
    "~/Library/Application Support/aio-coding-hub",
    "~/Library/Caches/aio-coding-hub",
    "~/Library/Preferences/com.aio-coding-hub.app.plist",
  ]
end
