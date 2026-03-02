# Using Your Installed Chrome Browser with Your Profile

This guide explains how to use your locally-installed Chrome browser — including your real Chrome profile with saved logins, cookies, and extensions — with `playwright-cli` via the Chrome DevTools Protocol (CDP).

---

## Security Restrictions (Chrome v136+, enforced 2025+)

As of Chrome v136, Google enforced stricter CDP security rules that **all automation must respect**:

1. **Remote debugging is blocked on the default profile directory.** Chrome refuses to start with `--remote-debugging-port` when `--user-data-dir` points to Chrome's actual system-default data directory (e.g., `~/.config/google-chrome`). A non-default, custom `--user-data-dir` is required.

2. **CDP binds to 127.0.0.1 only.** `--remote-debugging-address=0.0.0.0` is silently overridden to `127.0.0.1`. CDP is local-only.

3. **SingletonLock prevents concurrent access.** Chrome locks its profile directory with a `SingletonLock` file while it is running. Any attempt to open the same directory in a second browser (including a Playwright-managed one) will fail immediately.

**The safe, required workflow is always: copy the profile to a new directory, then use the copy.**

---

## Step 1 — Find Your Chrome Profile Path

Open `chrome://version` in Chrome and look at the **Profile Path** field. That is the exact directory to copy.

Default locations by platform:

| Platform | User Data Directory                                     | Default Profile Subdir |
|----------|---------------------------------------------------------|------------------------|
| Linux    | `~/.config/google-chrome/`                             | `Default`              |
| macOS    | `~/Library/Application Support/Google/Chrome/`         | `Default`              |
| Windows  | `%LOCALAPPDATA%\Google\Chrome\User Data\`              | `Default`              |

Named profiles are stored as numbered subdirectories: `Profile 1`, `Profile 2`, etc.

```bash
# Linux/macOS: list available profiles
ls ~/.config/google-chrome/           # Linux
ls ~/Library/Application\ Support/Google/Chrome/  # macOS
```

---

## Step 2 — Close Chrome Completely

Chrome **must be fully quit** before copying its profile. If Chrome is open, the `SingletonLock` file exists and any copy will be unusable.

```bash
# Linux — check and kill Chrome
pgrep -x chrome && pkill -x chrome || echo "Chrome not running"

# macOS — quit Chrome gracefully, then force-kill if needed
osascript -e 'quit app "Google Chrome"'
sleep 2
pkill -x "Google Chrome" 2>/dev/null || true

# Windows (PowerShell)
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
```

---

## Step 3 — Copy the Profile to a Safe Location

Copy only the specific profile subdirectory (e.g., `Default` or `Profile 1`), not the entire User Data directory. Use a dedicated, persistent destination like `~/.playwright-chrome/`.

```bash
# Linux — copy Default profile
mkdir -p ~/.playwright-chrome
cp -r ~/.config/google-chrome/Default ~/.playwright-chrome/Default

# Linux — copy a named profile (Profile 1)
cp -r ~/.config/google-chrome/"Profile 1" ~/.playwright-chrome/"Profile 1"

# macOS — copy Default profile
mkdir -p ~/.playwright-chrome
cp -r ~/Library/Application\ Support/Google/Chrome/Default ~/.playwright-chrome/Default

# Windows (PowerShell) — copy Default profile
$src = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$dst = "$env:USERPROFILE\.playwright-chrome\Default"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Recurse -Force $src $dst
```

---

## Step 4 — Remove Lock Files from the Copy

Chrome may have left lock files inside the profile even after closing cleanly. Always remove them from the **copied** directory before use.

```bash
# Linux/macOS
rm -f ~/.playwright-chrome/Default/SingletonLock
rm -f ~/.playwright-chrome/Default/SingletonSocket
rm -f ~/.playwright-chrome/Default/SingletonCookie

# Windows (PowerShell)
$profileCopy = "$env:USERPROFILE\.playwright-chrome\Default"
Remove-Item "$profileCopy\SingletonLock"   -ErrorAction SilentlyContinue
Remove-Item "$profileCopy\SingletonSocket" -ErrorAction SilentlyContinue
Remove-Item "$profileCopy\SingletonCookie" -ErrorAction SilentlyContinue
```

---

## Step 5 — Open playwright-cli with Your Copied Profile

Use the `--profile` flag pointing to the **copied** profile directory. The `--browser=chrome` flag ensures playwright-cli uses the system-installed Chrome.

```bash
# Linux
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default https://example.com

# macOS
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default https://example.com

# Windows (PowerShell)
playwright-cli open --browser=chrome --profile="$env:USERPROFILE\.playwright-chrome\Default" https://example.com

# With a named session for reuse across commands
playwright-cli -s=myprofile open --browser=chrome --profile=~/.playwright-chrome/Default https://example.com
playwright-cli -s=myprofile snapshot
playwright-cli -s=myprofile close
```

---

## Automated Profile Selection with Human Input

If you are automating a task that requires a specific Chrome profile but encounter multiple options or are unsure which one the user prefers, you should **proactively ask for clarification**.

### When to ask:
- When listing `~/.config/google-chrome/` (Linux) or similar directories reveals multiple profile folders (e.g., `Default`, `Profile 1`, `Profile 2`).
- When the user's request is ambiguous about which browser context to use.
- When a previously used profile is no longer accessible or valid.

### How to ask

If the agent has access to a tool that allows structured user queries with selectable options, it should use that tool. Otherwise, the agent's final message must:
- Clearly state the clarification question
- Provide concise, well-structured answer options (if applicable)
- Format the query and options in Markdown
- Explicitly stop further processing
- Resume execution only after the user responds in the next message

Asking for clarification ensures you don't make incorrect assumptions that could lead to using the wrong account or credentials.

---

---

## Alternative: Launch Chrome via CDP then Connect

Use this approach when you want Chrome running visibly in headed mode while playwright-cli connects to it, or when you need Chrome to stay open between automation runs.

### Launch Chrome with remote debugging

Chrome must be launched with both `--remote-debugging-port` and a **non-default** `--user-data-dir` (Chrome v136+ requirement):

```bash
# Linux
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --no-first-run \
  --no-default-browser-check \
  --profile-directory=Default &

# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --no-first-run \
  --no-default-browser-check \
  --profile-directory=Default &

# Windows (PowerShell)
Start-Process "$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe" -ArgumentList @(
  "--remote-debugging-port=9222",
  "--user-data-dir=$env:USERPROFILE\.playwright-chrome",
  "--no-first-run",
  "--no-default-browser-check",
  "--profile-directory=Default"
)
```

### Connect playwright-cli to the running Chrome

```bash
# Connect to the already-running Chrome instance
playwright-cli open --cdp-endpoint=http://localhost:9222

# Then interact normally
playwright-cli goto https://example.com
playwright-cli snapshot
```

---

## About Cookies and Encryption

Chrome encrypts cookies at rest using platform-specific mechanisms. When you copy a profile, cookie availability depends on the platform:

| Platform | Cookie Encryption | Behavior After Profile Copy |
|----------|-------------------|-----------------------------|
| Linux    | GNOME Keyring / KWallet (`v10`/`v11` AES) | Cookies decrypt correctly when the same user runs the copied profile, as the keyring key is per-user |
| macOS    | System Keychain (`Chrome Safe Storage` key) | Cookies decrypt correctly on the same Mac/user account |
| Windows  | DPAPI (bound to current Windows user + machine) | Cookies decrypt correctly on the same machine/user account |

**localStorage, IndexedDB, and sessionStorage** are stored unencrypted and transfer fully intact.

**Re-login may still be required** if:
- Session cookies have expired since the profile was copied
- The site uses device fingerprinting or IP binding
- The profile copy is being used on a different machine or user account

---

## One-Shot Helper Script (Linux/macOS)

Save this as `refresh-playwright-chrome.sh` and run it whenever you need to sync a fresh copy of your Chrome profile:

```bash
#!/usr/bin/env bash
set -euo pipefail

CHROME_PROFILE="${HOME}/.config/google-chrome/Default"      # Linux default
# CHROME_PROFILE="${HOME}/Library/Application Support/Google/Chrome/Default"  # macOS

DEST="${HOME}/.playwright-chrome/Default"

echo "Checking Chrome is not running..."
if pgrep -x chrome > /dev/null 2>&1; then
  echo "ERROR: Chrome is still running. Please quit Chrome first."
  exit 1
fi

echo "Copying Chrome profile to ${DEST}..."
rm -rf "${DEST}"
cp -r "${CHROME_PROFILE}" "${DEST}"

echo "Removing lock files..."
rm -f "${DEST}/SingletonLock"
rm -f "${DEST}/SingletonSocket"
rm -f "${DEST}/SingletonCookie"

echo "Done. Profile ready at: ${DEST}"
echo "Run: playwright-cli open --browser=chrome --profile=${DEST} https://example.com"
```

---

## Common Issues and Fixes

### `SingletonLock: File exists` error

The profile is locked. Either Chrome is still running, or a previous session crashed.

```bash
# Check for Chrome processes
pgrep -a chrome

# If safe, remove the lock
rm -f ~/.playwright-chrome/Default/SingletonLock
```

### Blank page / "stuck loading" on CDP connect

Chrome v136+ restriction: `--remote-debugging-port` requires `--user-data-dir` to be a non-system path. Ensure you are using a copied profile path and not the original system directory.

### Extensions not working

Extensions from your copied profile may not load in some automation modes. To enable them, avoid `--headless` mode and launch Chrome in headed mode:

```bash
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default --headed https://example.com
```

### Profile becomes stale (cookies expired, not logged in)

Re-copy the profile from your live Chrome installation:

```bash
pkill -x chrome || true
rm -rf ~/.playwright-chrome/Default
cp -r ~/.config/google-chrome/Default ~/.playwright-chrome/Default
rm -f ~/.playwright-chrome/Default/SingletonLock
```

---

## Full Example: Authenticated Scraping with Your Chrome Profile

```bash
#!/usr/bin/env bash
# Scrape an authenticated page using your real Chrome profile

PROFILE_SRC="${HOME}/.config/google-chrome/Default"
PROFILE_DST="${HOME}/.playwright-chrome/Default"

# 1. Quit Chrome
pkill -x chrome 2>/dev/null || true
sleep 1

# 2. Sync profile
rm -rf "${PROFILE_DST}"
cp -r "${PROFILE_SRC}" "${PROFILE_DST}"
rm -f "${PROFILE_DST}/SingletonLock"

# 3. Run automation
playwright-cli open --browser=chrome --profile="${PROFILE_DST}" https://app.example.com/dashboard
playwright-cli snapshot --filename=dashboard.yaml
playwright-cli close
```
