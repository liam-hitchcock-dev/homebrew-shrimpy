import AppKit

// MARK: - Claude Hook Manager

func shrimpyHookScriptPath() -> String {
    return NSHomeDirectory() + "/.claude/shrimpy-hook.py"
}

func currentClaudeHookCommand() -> String {
    return "python3 \(shrimpyHookScriptPath())"
}

func writeHookScript() {
    let binaryPath = Bundle.main.bundlePath + "/Contents/MacOS/Shrimpy"
    let script = """
#!/usr/bin/env python3
import sys, json, os, subprocess, re
data = json.load(sys.stdin)

m = data.get('message', '') or 'Claude needs your input'

transcript_path = data.get('transcript_path', '')
tab_title = None
if transcript_path:
    try:
        with open(transcript_path) as f:
            for line in f:
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                if obj.get('type') != 'user':
                    continue
                content = obj.get('message', {}).get('content', '')
                if isinstance(content, str):
                    text = content.strip()
                    if text and '<' not in text:
                        tab_title = text[:50]
                        break
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get('type') == 'text':
                            text = block.get('text', '').strip()
                            if text and '<' not in text:
                                tab_title = text[:50]
                                break
                    if tab_title:
                        break
    except Exception:
        pass

folder_name = os.path.basename(data.get('cwd', '')) or 'Claude'
t = tab_title or folder_name
with open(os.path.expanduser('~/.claude/shrimpy-hook.log'), 'a') as f:
    f.write(json.dumps(data) + '\\n')
subprocess.run(['\(binaryPath)', m, '--title', t])
"""
    let path = shrimpyHookScriptPath()
    try? script.write(toFile: path, atomically: true, encoding: .utf8)
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: path)
}

func ensureClaudeNotificationHookInstalled() {
    writeHookScript()
    let settingsURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(kClaudeSettingsRelativePath)
    let fm = FileManager.default
    let hookCommand = currentClaudeHookCommand()

    do {
        try fm.createDirectory(
            at: settingsURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    } catch {
        NSLog("Shrimpy: failed to create ~/.claude directory: %@", error.localizedDescription)
        return
    }

    var root: [String: Any] = [:]
    if fm.fileExists(atPath: settingsURL.path) {
        do {
            let data = try Data(contentsOf: settingsURL)
            if !data.isEmpty {
                guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    NSLog("Shrimpy: ~/.claude/settings.json is not a JSON object; skipping hook sync")
                    return
                }
                root = parsed
            }
        } catch {
            NSLog("Shrimpy: failed to parse ~/.claude/settings.json: %@", error.localizedDescription)
            return
        }
    }

    var hooks = (root["hooks"] as? [String: Any]) ?? [:]
    let notificationRules = (hooks["Notification"] as? [[String: Any]]) ?? []

    let commandHook: [String: Any] = [
        "type": "command",
        "command": hookCommand
    ]

    var changed = false
    var updatedRules: [[String: Any]] = []
    var injected = false

    for var rule in notificationRules {
        let matcher = (rule["matcher"] as? String) ?? ""
        var hookItems = (rule["hooks"] as? [[String: Any]]) ?? []
        let hadShrimpyHook = hookItems.contains { item in
            guard let cmd = item["command"] as? String else { return false }
            return cmd.contains("shrimpy-hook.py") || cmd.contains("Shrimpy.app") || cmd.contains("/MacOS/Shrimpy")
        }

        let filtered = hookItems.filter { item in
            guard let cmd = item["command"] as? String else { return true }
            return !cmd.contains("shrimpy-hook.py") &&
                   !cmd.contains("Shrimpy.app") &&
                   !cmd.contains("/MacOS/Shrimpy")
        }
        if filtered.count != hookItems.count {
            hookItems = filtered
            changed = true
        }

        // Migrate old Shrimpy matcher rules to the structured matcher.
        if hadShrimpyHook && (matcher == "" || matcher == "*" || matcher == "permission_prompt|idle_prompt") {
            rule["matcher"] = kClaudeNotificationMatcher
            changed = true
        }

        let resolvedMatcher = (rule["matcher"] as? String) ?? matcher
        if resolvedMatcher == kClaudeNotificationMatcher {
            let hasCommand = hookItems.contains {
                ($0["type"] as? String) == "command" &&
                ($0["command"] as? String) == hookCommand
            }
            if !hasCommand {
                hookItems.append(commandHook)
                rule["hooks"] = hookItems
                changed = true
            }
            injected = true
        }

        updatedRules.append(rule)
    }

    if !injected {
        updatedRules.append([
            "matcher": kClaudeNotificationMatcher,
            "hooks": [commandHook]
        ])
        changed = true
    }

    if !changed { return }

    hooks["Notification"] = updatedRules
    root["hooks"] = hooks

    do {
        let out = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try out.write(to: settingsURL, options: .atomic)
    } catch {
        NSLog("Shrimpy: failed to write ~/.claude/settings.json: %@", error.localizedDescription)
    }
}

func isHookInstalled() -> Bool {
    let settingsURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(kClaudeSettingsRelativePath)
    let hookCommand = currentClaudeHookCommand()
    guard let data = try? Data(contentsOf: settingsURL),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let hooks = root["hooks"] as? [String: Any],
          let rules = hooks["Notification"] as? [[String: Any]] else {
        return false
    }
    return rules.contains { rule in
        let matcher = (rule["matcher"] as? String) ?? ""
        guard matcher == kClaudeNotificationMatcher else { return false }
        return ((rule["hooks"] as? [[String: Any]]) ?? []).contains {
            ($0["type"] as? String) == "command" &&
            ($0["command"] as? String) == hookCommand
        }
    }
}
