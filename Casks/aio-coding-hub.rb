cask "aio-coding-hub" do
  version "0.60.6"

  on_arm do
    sha256 "c41046702127c4ab0d90597dbc952143c70fe743f3dc4965cac81c361370613c"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-arm.zip"
  end
  on_intel do
    sha256 "d4cf8107a334d67909cbb1caaf26147a5176e4d5539d34ed58f42b14b715ce84"
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
