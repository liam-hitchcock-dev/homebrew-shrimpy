cask "shrimpy" do
  version "1.1.1"
  sha256 "25ff3c07c1be3af5fc51b5276e83ff7fe282dc6bfbbd4fa6ec63fda1082167ea"

  url "https://github.com/liam-hitchcock-dev/homebrew-shrimpy/releases/download/v#{version}/Shrimpy-#{version}.zip"
  name "Shrimpy"
  desc "macOS menubar notifier for Claude Code"
  homepage "https://github.com/liam-hitchcock-dev/homebrew-shrimpy"

  app "Shrimpy.app"

  postflight do
    system_command "/usr/bin/open",
                   args: ["-gj", "#{appdir}/Shrimpy.app"]
  end
end
