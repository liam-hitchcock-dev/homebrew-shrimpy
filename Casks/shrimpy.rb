cask "shrimpy" do
  version "1.1.1"
  sha256 "187d818b574f0b3ea4aef5968eb2eeccbed56b7b7cb4ce35339c3c5111340eca"

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
