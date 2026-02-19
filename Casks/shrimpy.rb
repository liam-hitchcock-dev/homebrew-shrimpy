cask "shrimpy" do
  version "1.0.0"
  sha256 "<fill in after first release>"

  url "https://github.com/liam-hitchcock-dev/shrimpy/releases/download/v#{version}/Shrimpy-#{version}.zip"
  name "Shrimpy"
  desc "macOS menubar notifier for Claude Code"
  homepage "https://github.com/liam-hitchcock-dev/shrimpy"

  app "Shrimpy.app"

  postflight do
    system_command "/usr/bin/open",
                   args: ["-gj", "#{appdir}/Shrimpy.app"]
  end
end
