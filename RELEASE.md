# Release Guide

Step-by-step instructions for cutting a signed, notarized release of Shrimpy.

---

## Prerequisites

- Xcode installed (for `codesign`, `xcrun notarytool`, `xcrun stapler`)
- Apple Developer account with a **Developer ID Application** certificate
- A GitHub account with a personal access token (PAT) that has `write` access to the `homebrew-shrimpy` tap repo

---

## 1. Export Developer ID Certificate as p12

1. Open **Keychain Access** → **My Certificates**
2. Find **Developer ID Application: Liam Hitchcock (C88QPDDXK4)**
3. Right-click → **Export** → save as `developer_id.p12`, set a strong password
4. Base64-encode it for GitHub:
   ```bash
   base64 -i developer_id.p12 | pbcopy
   ```

---

## 2. Create an App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com) → **Sign-In and Security** → **App-Specific Passwords**
2. Generate a new password named `Shrimpy Notarization`
3. Save it — you'll only see it once

---

## 3. Add GitHub Secrets

In the `shrimpy` repo settings → **Secrets and variables** → **Actions**, add:

| Secret name | Value |
|---|---|
| `DEVELOPER_ID_CERT_P12` | Base64-encoded p12 from step 1 |
| `DEVELOPER_ID_CERT_PASSWORD` | p12 export password |
| `APPLE_ID` | your Apple ID email |
| `APPLE_APP_SPECIFIC_PASSWORD` | app-specific password from step 2 |
| `APPLE_TEAM_ID` | `C88QPDDXK4` |
| `TAP_REPO_TOKEN` | GitHub PAT with write access to `homebrew-shrimpy` repo |

---

## 4. Create the Homebrew Tap Repo

1. Create a new GitHub repo: `liam-hitchcock-dev/homebrew-shrimpy`
2. Add the file `Casks/shrimpy.rb` (see template below — fill in SHA256 after first release)

```ruby
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
```

3. Add a `repository_dispatch` workflow so the main release workflow can update it automatically:

   `.github/workflows/update-formula.yml`:
   ```yaml
   name: Update Formula

   on:
     repository_dispatch:
       types: [update-formula]

   jobs:
     update:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Update shrimpy.rb
           run: |
             VERSION="${{ github.event.client_payload.version }}"
             SHA256="${{ github.event.client_payload.sha256 }}"
             sed -i "s/version \".*\"/version \"$VERSION\"/" Casks/shrimpy.rb
             sed -i "s/sha256 \".*\"/sha256 \"$SHA256\"/" Casks/shrimpy.rb
         - name: Commit and push
           run: |
             git config user.name "github-actions[bot]"
             git config user.email "github-actions[bot]@users.noreply.github.com"
             git add Casks/shrimpy.rb
             git commit -m "Update Shrimpy to v${{ github.event.client_payload.version }}"
             git push
   ```

---

## 5. Cut a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will:
1. Build the app
2. Sign with Developer ID
3. Notarize + staple
4. Zip and compute SHA256
5. Create a GitHub Release with the zip attached
6. Dispatch to the tap repo to update `shrimpy.rb`

---

## 6. Verify

```bash
brew tap liam-hitchcock-dev/shrimpy
brew install --cask shrimpy
```

- App should open without any Gatekeeper warning
- Menubar icon appears
- **Support Shrimpy ☕** opens https://buymeacoffee.com/liam.hitchcock

---

## Manual Release (without CI)

If you prefer to release locally:

```bash
# Set your Apple ID (team ID and developer ID are already in the Makefile)
export APPLE_ID=your@email.com

# Store your app-specific password in the keychain first:
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "$APPLE_ID" \
  --team-id C88QPDDXK4

# Then run:
make release
```

The zip and its SHA256 are printed at the end. Update `Casks/shrimpy.rb` manually with those values, then create the GitHub Release and upload the zip.
