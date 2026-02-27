# Shrimpy 🦐

A tiny macOS menubar app that notifies you when [Claude Code](https://claude.ai/code) needs your input.

## What it does

Shrimpy lives in your menubar and fires a macOS notification whenever Claude Code pauses and is waiting on you. Clicking the notification brings your terminal back into focus automatically.

![Shrimpy menubar icon](ShrimpyBar@2x.png)

## Features

- Menubar icon with pending notification indicator
- macOS notifications with configurable sound
- Click-to-focus: notifications bring your terminal back to the foreground
- Auto-configures Claude Code notification hook on launch
- Mute toggle
- Notification history (last 50)
- Launch at Login (macOS 13+)
- Single-instance: subsequent CLI calls post to the already-running app

## Installation

### Via Homebrew (recommended)

```bash
brew tap liam-hitchcock-dev/shrimpy
brew install --cask shrimpy
```

### Manual build

Build and install to `/Applications`:

```bash
make install
```

Or build only (outputs `Shrimpy.app` in the repo directory):

```bash
make build
```

Then launch it:

```bash
open /Applications/Shrimpy.app
```

Shrimpy will ask for notification permissions on first launch and auto-configure the Claude Code hook in `~/.claude/settings.json`. Enable **Launch at Login** in Settings so it starts automatically.

## Menu

| Item | Action |
|---|---|
| Go to Claude conversation | Focus the terminal that triggered the notification |
| Mute Notifications | Silence all notifications until toggled back |
| Notification History | Scrollable table of recent notifications |
| Settings... | Sound picker, Launch at Login toggle, test button |
| Quit | Exit Shrimpy |

## Supported terminals

Shrimpy walks the process tree to find which terminal launched Claude Code and focuses it when you click a notification:

- Terminal.app
- iTerm2
- Warp
- VS Code
- Hyper
- kitty
- Alacritty
- GoLand
- Xcode
