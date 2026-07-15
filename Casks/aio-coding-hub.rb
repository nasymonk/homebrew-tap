cask "aio-coding-hub" do
  version "0.60.14"

  on_arm do
    sha256 "d12818a5f3b8f72f313d5d7eae066dbf192ea16149369d509db8be65e7bdfd37"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-arm.zip"
  end
  on_intel do
    sha256 "25da2f6fa8205818cf489c985d94c0ec904cb9bcbd08ad9f22fc6884b61547be"
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
