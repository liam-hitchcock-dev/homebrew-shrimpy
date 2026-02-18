# Shrimpy 🦐

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

### 1. Build the app

```bash
swiftc Shrimpy.swift -o Shrimpy \
  -framework AppKit \
  -framework UserNotifications \
  -framework ServiceManagement
```

Then wrap it as an `.app` bundle and place it somewhere permanent, e.g. `~/.claude/Shrimpy.app`.

### 2. Launch it

```bash
open ~/.claude/Shrimpy.app
```

Shrimpy will ask for notification permissions on first launch. Enable **Launch at Login** in Settings so it starts automatically.

### 3. Claude Code hook setup

Shrimpy now auto-installs/repairs this hook in `~/.claude/settings.json` at launch:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "open -gj ~/.claude/Shrimpy.app --args \"$CLAUDE_NOTIFICATION_TITLE\""
          }
        ]
      }
    ]
  }
}
```

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
