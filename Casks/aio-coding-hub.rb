cask "aio-coding-hub" do
  version "0.60.12"

  on_arm do
    sha256 "d104f658efad3fb93abfea52e4914cb5e61064d9e3c55a29325014d8df985e9d"
    url "https://github.com/dyndynjyxa/aio-coding-hub/releases/download/aio-coding-hub-v#{version}/aio-coding-hub-macos-arm.zip"
  end
  on_intel do
    sha256 "6993c769188575740debf105681b87f1955fdb8d7b5c1bb79c304df75336c929"
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
