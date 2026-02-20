# Shrimpy 🦐

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-☕-yellow)](https://buymeacoffee.com/liam.hitchcock)

A tiny macOS menubar app that notifies you when [Claude Code](https://claude.ai/code) needs your input.

## What it does

Shrimpy lives in your menubar and fires a macOS notification whenever Claude Code pauses and is waiting on you. Clicking the notification brings your terminal back into focus automatically.

![Shrimpy menubar icon](ShrimpyBar@2x.png)

## Features

- Menubar icon with right-click menu
- macOS notifications with configurable sound
- "Open Terminal" action on notifications — focuses whichever terminal sent the request
- Auto-syncs `~/.claude/settings.json` Notification hook on launch
- Mute toggle
- Notification history (last 50)
- Launch at Login (macOS 13+)
- Single-instance: subsequent CLI calls post to the already-running app via distributed notifications

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

Shrimpy will ask for notification permissions on first launch. Enable **Launch at Login** in Settings so it starts automatically.

### 3. Claude Code hook setup

Shrimpy now auto-installs/repairs this hook in `~/.claude/settings.json` at launch:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "^(permission_prompt|idle_prompt)$",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/shrimpy-hook.py"
          }
        ]
      }
    ]
  }
}
```

This matcher filters on `notification_type`, so Shrimpy only runs for actionable prompts.

Manual equivalent command:

```bash
open -gj ~/.claude/Shrimpy.app --args "Claude needs input" --title "My Project"
```

## Menu

| Item | Action |
|---|---|
| Settings… | Sound picker, Launch at Login toggle, test button |
| Mute Notifications | Silence all notifications until toggled back |
| Notification History | Scrollable table of recent notifications |
| Test Notification | Fire a test notification immediately |
| Support Shrimpy ☕ | Opens Buy Me a Coffee page |
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

## Codex wrapper setup

Use the provided wrapper so Codex sessions notify via Shrimpy:

```bash
chmod +x scripts/codex-notify.sh
make codex ARGS='your codex args here'
```

Config lives in `config/codex-notify.conf`:

- `ENABLE_NOTIFY=1` to enable (or `0` to disable)
- `SHRIMPY_APP_PATH` for where Shrimpy is installed
- `CODEX_BIN` for the Codex executable name/path
- `PROJECT_TITLE` for notification title text

Send a test notification without running Codex:

```bash
make codex-notify-test
```
