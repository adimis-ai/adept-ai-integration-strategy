# Stealth Mode — Undetectable Chrome Automation

This guide covers how to launch Chrome so that:
- The **"Chrome is being controlled by automated test software"** banner never appears
- `navigator.webdriver` is not exposed (the primary detection signal used by anti-bot systems)
- The browser fingerprint matches a real user session as closely as possible

---

## Root Cause: What Triggers Detection

When Playwright (or playwright-cli) launches Chrome, it injects `--enable-automation` into Chrome's launch arguments by default. This switch does two things:
1. Shows the **"Chrome is being controlled by automated test software"** info bar
2. Sets `navigator.webdriver = true` in every page context

**`--disable-infobars` is permanently deprecated as of Chrome 65 and does nothing — do not use it.**

The correct fix is to **exclude `--enable-automation`** from Chrome's launch args and explicitly disable the `AutomationControlled` Blink feature.

---

## Approach 1: playwright-cli Config File (Recommended)

Create a stealth config file that playwright-cli passes to Playwright's launch options.

### `.playwright/stealth.json`
```json
{
  "launchOptions": {
    "ignoreDefaultArgs": ["--enable-automation"],
    "args": [
      "--disable-blink-features=AutomationControlled",
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-popup-blocking"
    ]
  }
}
```

### Usage
```bash
# Open with stealth config (in-memory profile)
playwright-cli open --browser=chrome --config=.playwright/stealth.json https://example.com

# Open with stealth config + your real Chrome profile (copy required — see user-chrome-profile.md)
playwright-cli open --browser=chrome \
  --profile=~/.playwright-chrome/Default \
  --config=.playwright/stealth.json \
  https://example.com

# With a named session for multi-step workflows
playwright-cli -s=stealth open --browser=chrome \
  --profile=~/.playwright-chrome/Default \
  --config=.playwright/stealth.json \
  https://example.com
```

---

## Approach 2: CDP Connect to Manually Launched Chrome

When you launch Chrome yourself, you control all flags — and simply never include `--enable-automation`. Chrome will not show the banner and will not set `navigator.webdriver`.

### Linux
```bash
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --profile-directory=Default \
  --disable-blink-features=AutomationControlled \
  --no-first-run \
  --no-default-browser-check &

# Connect playwright-cli (no --enable-automation injected)
playwright-cli open --cdp-endpoint=http://localhost:9222
```

### macOS
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=~/.playwright-chrome \
  --profile-directory=Default \
  --disable-blink-features=AutomationControlled \
  --no-first-run \
  --no-default-browser-check &

playwright-cli open --cdp-endpoint=http://localhost:9222
```

### Windows (PowerShell)
```powershell
Start-Process "$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe" -ArgumentList @(
  "--remote-debugging-port=9222",
  "--user-data-dir=$env:USERPROFILE\.playwright-chrome",
  "--profile-directory=Default",
  "--disable-blink-features=AutomationControlled",
  "--no-first-run",
  "--no-default-browser-check"
)

playwright-cli open --cdp-endpoint=http://localhost:9222
```

---

## Step 2: Patch `navigator.webdriver` for All Future Pages

After opening the browser (either approach), inject an init script so the patch applies to every page the browser navigates to — including new tabs and frames:

```bash
playwright-cli run-code "async page => {
  await page.context().addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  });
}"
```

To verify the patch is active on the current page:
```bash
playwright-cli eval "navigator.webdriver"
# Should return: undefined
```

---

## Step 3: Additional Stealth Patches (Optional but Recommended)

Patch additional fingerprinting signals that anti-bot systems commonly check. Run this after opening the browser:

```bash
playwright-cli run-code "async page => {
  await page.context().addInitScript(() => {
    // 1. Remove webdriver flag
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });

    // 2. Restore window.chrome (missing in automation contexts)
    if (!window.chrome) {
      window.chrome = { runtime: {}, loadTimes: () => {}, csi: () => {}, app: {} };
    }

    // 3. Realistic plugin list (empty plugins array is a bot signal)
    Object.defineProperty(navigator, 'plugins', {
      get: () => [1, 2, 3, 4, 5],
    });

    // 4. Realistic language list
    Object.defineProperty(navigator, 'languages', {
      get: () => ['en-US', 'en'],
    });
  });
}"
```

---

## Stealth Config + Profile: Full Combined Example

```bash
#!/usr/bin/env bash
# Full stealth setup: real Chrome profile + no automation signals

PROFILE_SRC="${HOME}/.config/google-chrome/Default"   # Linux; adjust for macOS/Windows
PROFILE_DST="${HOME}/.playwright-chrome/Default"
CONFIG=".playwright/stealth.json"

# 1. Quit Chrome
pkill -x chrome 2>/dev/null || true
sleep 1

# 2. Sync profile copy
rm -rf "${PROFILE_DST}"
cp -r "${PROFILE_SRC}" "${PROFILE_DST}"
rm -f "${PROFILE_DST}/SingletonLock"

# 3. Open in stealth mode with real profile
playwright-cli -s=stealth open \
  --browser=chrome \
  --profile="${PROFILE_DST}" \
  --config="${CONFIG}" \
  https://example.com

# 4. Inject navigator patches for all future pages
playwright-cli -s=stealth run-code "async page => {
  await page.context().addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    if (!window.chrome) window.chrome = { runtime: {} };
  });
}"

# 5. Proceed with automation
playwright-cli -s=stealth snapshot
playwright-cli -s=stealth close
```

---

## Verification Checklist

After launching, confirm stealth mode is active:

```bash
# Should return: undefined  (not true)
playwright-cli eval "navigator.webdriver"

# Should return: object  (present in a real Chrome)
playwright-cli eval "typeof window.chrome"

# Should return a non-empty string matching your Chrome version
playwright-cli eval "navigator.userAgent"

# Should NOT contain 'HeadlessChrome' if running headed
playwright-cli eval "navigator.userAgent.includes('HeadlessChrome')"
```

---

## What Each Flag Does

| Flag / Setting | Effect |
|---|---|
| `ignoreDefaultArgs: ["--enable-automation"]` | Removes the banner + prevents Playwright from injecting the automation switch |
| `--disable-blink-features=AutomationControlled` | Prevents Blink from exposing `navigator.webdriver = true` |
| `--no-first-run` | Suppresses Chrome's first-run welcome dialog |
| `--no-default-browser-check` | Suppresses "make Chrome your default browser" prompts |
| `--disable-popup-blocking` | Prevents some sites from triggering popups that reveal automation |
| `addInitScript()` webdriver patch | Overrides `navigator.webdriver` in every page/frame context, including after navigation |
| `window.chrome` patch | Restores the `chrome` global that real Chrome exposes but CDP-connected sessions sometimes lack |

---

## Notes

- **Headed mode is harder to detect than headless.** Use `--headed` for maximum stealth. Headless Chrome (`--headless=new`) still leaks signals via font metrics, GPU capabilities, and missing system APIs that anti-bot systems fingerprint.
- **These flags work with real Chrome (`--browser=chrome`), not Playwright's bundled Chromium.** The bundled Chromium does not match a real browser's version, extension ecosystem, or GPU fingerprint.
- **Profile copy is still required** when combining stealth mode with your real Chrome profile (see [user-chrome-profile.md](user-chrome-profile.md)).
