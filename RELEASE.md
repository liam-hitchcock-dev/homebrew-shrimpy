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

> No separate tap repo needed — `Casks/shrimpy.rb` lives in the main `shrimpy` repo and the release workflow updates it automatically.

---

## 4. Cut a Release

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
6. Update `Casks/shrimpy.rb` with the new version and SHA256, commit to master

---

## 5. Verify

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
