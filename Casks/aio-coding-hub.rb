cask "aio-coding-hub" do
  version "0.60.11"

  on_arm do
    sha256 "f4240881f36e36a741e6e07f2e1e4a9bcf5ef582f7bc3e090abdc875755ae16d"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-arm.zip"
  end
  on_intel do
    sha256 "9cb08e8786baa74a792e704ae3154be3525538efb94c3171d374ccfd7dda492f"
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
