---
name: playwright-cli
description: Automates browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.
---

# Browser Automation with playwright-cli

> **Skill Chain - Next Read:** After understanding browser automation, recommend reading the [Market Research](../market-research/SKILL.md) skill to see how these tools are applied for intelligence gathering.

## Quick start

```bash
# open new browser
playwright-cli open
# navigate to a page
playwright-cli goto https://playwright.dev
# interact with the page using refs from the snapshot
playwright-cli click e15
playwright-cli type "page.click"
playwright-cli press Enter
# take a screenshot (rarely used, as snapshot is more common)
playwright-cli screenshot
# close the browser
playwright-cli close
```

## Commands

### Core

```bash
playwright-cli open
# open and navigate right away
playwright-cli open https://example.com/
playwright-cli goto https://playwright.dev
playwright-cli type "search query"
playwright-cli click e3
playwright-cli dblclick e7
playwright-cli fill e5 "user@example.com"
playwright-cli drag e2 e8
playwright-cli hover e4
playwright-cli select e9 "option-value"
playwright-cli upload ./document.pdf
playwright-cli check e12
playwright-cli uncheck e12
playwright-cli snapshot
playwright-cli snapshot --filename=after-click.yaml
playwright-cli eval "document.title"
playwright-cli eval "el => el.textContent" e5
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
playwright-cli resize 1920 1080
playwright-cli close
```

### Navigation

```bash
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

### Keyboard

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
```

### Mouse

```bash
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mouseup right
playwright-cli mousewheel 0 100
```

### Save as

```bash
playwright-cli screenshot
playwright-cli screenshot e5
playwright-cli screenshot --filename=page.png
playwright-cli pdf --filename=page.pdf
```

### Tabs

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-close 2
playwright-cli tab-select 0
```

### Storage

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json

# Cookies
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id abc123
playwright-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear

# LocalStorage
playwright-cli localstorage-list
playwright-cli localstorage-get theme
playwright-cli localstorage-set theme dark
playwright-cli localstorage-delete theme
playwright-cli localstorage-clear

# SessionStorage
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

### Network

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

### DevTools

```bash
playwright-cli console
playwright-cli console warning
playwright-cli network
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start
playwright-cli video-stop video.webm
```

## Open parameters
```bash
# Use specific browser when creating session
playwright-cli open --browser=chrome
playwright-cli open --browser=firefox
playwright-cli open --browser=webkit
playwright-cli open --browser=msedge
# Connect to browser via extension
playwright-cli open --extension

# Use persistent profile (by default profile is in-memory)
playwright-cli open --persistent
# Use persistent profile with custom directory
playwright-cli open --profile=/path/to/profile

# Use the user's installed Chrome with their real profile (copy required — see below)
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default

# Connect to a running Chrome instance via CDP
playwright-cli open --cdp-endpoint=http://localhost:9222

# Start with config file
playwright-cli open --config=my-config.json

# Close the browser
playwright-cli close
# Delete user data for the default session
playwright-cli delete-data
```

## Using Your Installed Chrome with Your Profile

Chrome v136+ enforces two critical security rules that affect all automation:
1. **Remote debugging is blocked on the default profile directory** — `--user-data-dir` must point to a non-system path.
2. **SingletonLock prevents concurrent access** — Chrome locks its profile while running; a second instance using the same directory will fail.

**The required workflow: copy the profile first, then use the copy.**

### Quick setup — Linux
```bash
# 1. Quit Chrome
pkill -x chrome 2>/dev/null || true

# 2. Copy your profile (Default, or Profile 1, Profile 2, etc.)
mkdir -p ~/.playwright-chrome
cp -r ~/.config/google-chrome/Default ~/.playwright-chrome/Default
rm -f ~/.playwright-chrome/Default/SingletonLock

# 3. Open playwright-cli with the copied profile
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default https://example.com
```

### Handling Profile Uncertainty

If you're unsure which profile the user wants to use (e.g., they have multiple profiles like "Default", "Work", "Personal"), ask them for clarification.

**How to ask:**

If the agent has access to a tool that allows structured user queries with selectable options, it should use that tool. Otherwise, the agent's final message must:
- Clearly state the clarification question
- Provide concise, well-structured answer options (if applicable)
- Format the query and options in Markdown
- Explicitly stop further processing
- Resume execution only after the user responds in the next message

### Quick setup — macOS
```bash
# 1. Quit Chrome
osascript -e 'quit app "Google Chrome"' && sleep 2

# 2. Copy your profile
mkdir -p ~/.playwright-chrome
cp -r ~/Library/Application\ Support/Google/Chrome/Default ~/.playwright-chrome/Default
rm -f ~/.playwright-chrome/Default/SingletonLock

# 3. Open playwright-cli with the copied profile
playwright-cli open --browser=chrome --profile=~/.playwright-chrome/Default https://example.com
```

### Quick setup — Windows (PowerShell)
```powershell
# 1. Quit Chrome
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Copy your profile
$src = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default"
$dst = "$env:USERPROFILE\.playwright-chrome\Default"
Copy-Item -Recurse -Force $src $dst
Remove-Item "$dst\SingletonLock" -ErrorAction SilentlyContinue

# 3. Open playwright-cli with the copied profile
playwright-cli open --browser=chrome --profile="$env:USERPROFILE\.playwright-chrome\Default" https://example.com
```

### Connect to a running Chrome via CDP (Chrome v136+ compliant)
```bash
# Launch Chrome with remote debugging — must use a non-default --user-data-dir (Chrome v136+ requirement)
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --profile-directory=Default \
  --no-first-run &

# Connect playwright-cli to the running Chrome instance
playwright-cli open --cdp-endpoint=http://localhost:9222
playwright-cli snapshot
```

See the full guide for named profiles, cookie encryption details, troubleshooting, and helper scripts: **[references/user-chrome-profile.md](references/user-chrome-profile.md)**

## Stealth Mode — Hide Automation from Chrome and Websites

By default, Playwright injects `--enable-automation` into Chrome's launch args. This causes:
- The **"Chrome is being controlled by automated test software"** banner to appear
- `navigator.webdriver = true` — the primary signal anti-bot systems check

**`--disable-infobars` is permanently removed in Chrome 65+ and does nothing — never use it.**

### Create a stealth config file

Create `.playwright/stealth.json` once and reuse it across sessions:

```json
{
  "launchOptions": {
    "ignoreDefaultArgs": ["--enable-automation"],
    "args": [
      "--disable-blink-features=AutomationControlled",
      "--no-first-run",
      "--no-default-browser-check"
    ]
  }
}
```

### Use it when opening a browser session

```bash
# No banner, navigator.webdriver not exposed
playwright-cli open --browser=chrome --config=.playwright/stealth.json https://example.com

# Combined: stealth + real Chrome profile (Linux)
playwright-cli open --browser=chrome \
  --profile=~/.playwright-chrome/Default \
  --config=.playwright/stealth.json \
  https://example.com
```

### Patch navigator.webdriver for all future pages

After opening, inject an init script that persists across navigations:

```bash
playwright-cli run-code "async page => {
  await page.context().addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    if (!window.chrome) window.chrome = { runtime: {} };
  });
}"

# Verify: should return undefined
playwright-cli eval "navigator.webdriver"
```

### CDP approach: launch Chrome yourself (no --enable-automation ever injected)

```bash
# Linux — Chrome launched without automation flags, then connect
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --profile-directory=Default \
  --disable-blink-features=AutomationControlled \
  --no-first-run &

playwright-cli open --cdp-endpoint=http://localhost:9222
```

See the full stealth guide with verification checklist, Windows/macOS variants, and additional fingerprint patches: **[references/stealth-mode.md](references/stealth-mode.md)**

## Snapshots

After each command, playwright-cli provides a snapshot of the current browser state.

```bash
> playwright-cli goto https://example.com
### Page
- Page URL: https://example.com/
- Page Title: Example Domain
### Snapshot
[Snapshot](.playwright-cli/page-2026-02-14T19-22-42-679Z.yml)
```

You can also take a snapshot on demand using `playwright-cli snapshot` command.

If `--filename` is not provided, a new snapshot file is created with a timestamp. Default to automatic file naming, use `--filename=` when artifact is a part of the workflow result.

## Browser Sessions

```bash
# create new browser session named "mysession" with persistent profile
playwright-cli -s=mysession open example.com --persistent
# same with manually specified profile directory (use when requested explicitly)
playwright-cli -s=mysession open example.com --profile=/path/to/profile
playwright-cli -s=mysession click e6
playwright-cli -s=mysession close  # stop a named browser
playwright-cli -s=mysession delete-data  # delete user data for persistent session

playwright-cli list
# Close all browsers
playwright-cli close-all
# Forcefully kill all browser processes
playwright-cli kill-all
```

## Local installation

In some cases user might want to install playwright-cli locally. If running globally available `playwright-cli` binary fails, use `npx playwright-cli` to run the commands. For example:

```bash
npx playwright-cli open https://example.com
npx playwright-cli click e1
```

## Example: Form submission

```bash
playwright-cli open https://example.com/form
playwright-cli snapshot

playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli snapshot
playwright-cli close
```

## Example: Multi-tab workflow

```bash
playwright-cli open https://example.com
playwright-cli tab-new https://example.com/other
playwright-cli tab-list
playwright-cli tab-select 0
playwright-cli snapshot
playwright-cli close
```

## Example: Debugging with DevTools

```bash
playwright-cli open https://example.com
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console
playwright-cli network
playwright-cli close
```

```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli tracing-stop
playwright-cli close
```

## Specific tasks

* **Request mocking** [references/request-mocking.md](references/request-mocking.md)
* **Running Playwright code** [references/running-code.md](references/running-code.md)
* **Browser session management** [references/session-management.md](references/session-management.md)
* **Storage state (cookies, localStorage)** [references/storage-state.md](references/storage-state.md)
* **Test generation** [references/test-generation.md](references/test-generation.md)
* **Tracing** [references/tracing.md](references/tracing.md)
* **Video recording** [references/video-recording.md](references/video-recording.md)
* **Using user's installed Chrome browser with their profile** [references/user-chrome-profile.md](references/user-chrome-profile.md)
* **Stealth mode (hide automation banner, navigator.webdriver)** [references/stealth-mode.md](references/stealth-mode.md)
