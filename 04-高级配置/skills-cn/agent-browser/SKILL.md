---
name: agent-browser
description: Browser automation CLI optimized for AI agents with CDP-first connection and persistent user-data-dir for session reuse
metadata: {"clawdbot":{"emoji":"🌐","requires":{"commands":["agent-browser"]},"homepage":"https://github.com/vercel-labs/agent-browser"}}
---

# Agent Browser Skill (CDP-First)

Fast browser automation using accessibility tree snapshots with refs for deterministic element selection.

**🔌 PRIORITY: Always connect to existing browser via CDP first, launch new browser only if needed.**
**💾 SESSION RULE: When launching a browser manually, always set a persistent `--user-data-dir` so login state can be reused.**
**🗂️ TAB RULE: For different URLs, always open a new tab. Only refresh or continue in the same tab when working on the same URL/page context.**

## Why CDP-First Approach?

### Advantages of CDP Connection:
- ✅ **Preserve login state** - Reuse existing cookies and sessions
- ✅ **Faster** - No browser startup overhead
- ✅ **Extension support** - Access to browser extensions
- ✅ **User context** - Work in user's normal browsing environment
- ✅ **Less resource** - Don't duplicate browser processes

### When to Use Each Approach:

**Use CDP connection (Priority):**
- ✅ User has browser already running
- ✅ Need to access logged-in sessions
- ✅ Testing with extensions installed
- ✅ Quick automation tasks

**Launch new browser (Fallback):**
- ❌ No browser running with CDP
- ❌ Need isolated clean environment
- ❌ Testing multi-user scenarios
- ❌ Automated headless workflows

## CDP Setup Guide

### 1. Check Existing Browser CDP

```bash
# Check if port 9222 is in use (Chrome/Edge default)
netstat -ano | findstr :9222

# If occupied, get the PID
tasklist /FI "PID eq <PID>"
```

### 2. Start Browser with CDP Enabled

**Windows (Edge/Chrome):**
```powershell
# Stop all instances first
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue

# Start with CDP and persistent session directory
& "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="D:\temp\chrome-debug"

# Or Chrome
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="D:\temp\chrome-debug"
```

**macOS/Linux:**
```bash
# macOS Chrome
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="$HOME/Library/Application Support/OpenClaw/chrome-debug"

# macOS Edge
/Applications/Microsoft\ Edge.app/Contents/MacOS/Microsoft\ Edge --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="$HOME/Library/Application Support/OpenClaw/chrome-debug"

# Linux Chrome
google-chrome --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="$HOME/.config/openclaw/chrome-debug"

# Linux Edge
microsoft-edge --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --user-data-dir="$HOME/.config/openclaw/chrome-debug"
```

### Recommended Persistent Profile Paths

- Windows: `D:\temp\chrome-debug`
- macOS: `$HOME/Library/Application Support/OpenClaw/chrome-debug`
- Linux: `$HOME/.config/openclaw/chrome-debug`

Use the same directory every time so cookies, sessions, and login state can be reused across runs.

### 3. Verify CDP is Running

```bash
# Test CDP endpoint
curl http://127.0.0.1:9222/json/version

# Should return JSON with webSocketDebuggerUrl
```

## Core Workflow (CDP-First)

### Tab Management Rule

- **Different URL task**: open a new tab first, then navigate in that new tab
- **Same URL task**: keep using the current tab and refresh if needed
- **Do not reuse an old tab for unrelated websites or unrelated page flows**
- **Preserve the original tab context whenever possible**, especially when the user may be logged in or reviewing information there

### URL Handling Heuristic

Use the current tab only when one of these is true:
- Same page needs another action
- Same site flow is continuing in context
- Same URL needs refresh / retry / re-snapshot

Open a new tab when one of these is true:
- The task target URL changes to a different website
- The task starts a new independent page flow
- The current tab contains user context that should not be interrupted
- You need to compare two pages side by side

### Method 1: Auto-Connect (Recommended)

```bash
# 1. Start browser with CDP (see setup above)
# 2. Auto-discover and connect
agent-browser --auto-connect snapshot -i --json

# 3. Navigate if needed
agent-browser --auto-connect open https://example.com

# 4. Work normally
agent-browser --auto-connect snapshot -i --json
agent-browser --auto-connect click @e2
```

### Method 2: Explicit CDP Port

```bash
# Connect to specific CDP port
agent-browser --cdp 9222 snapshot -i --json
agent-browser --cdp 9222 open https://example.com
```

### Method 3: Fallback to New Browser

```bash
# Only if CDP connection fails
agent-browser open https://example.com
```

## Connection Decision Tree

```
Start Task
    ↓
Check: Is browser running with CDP?
    ↓ YES
    Use --auto-connect or --cdp 9222
    ↓ NO
    Check: Should I launch new browser?
    ↓ YES
    Use agent-browser open (no CDP flags)
    ↓ NO
    Ask user to start browser with CDP
```

## Key Commands (CDP-Aware)

### Connection
```bash
agent-browser --auto-connect           # Auto-discover CDP browser
agent-browser --cdp 9222               # Connect to specific port
agent-browser --cdp http://127.0.0.1:9222  # Full URL
```

### Navigation
```bash
# With CDP connection
agent-browser --auto-connect open https://example.com
agent-browser --cdp 9222 back
agent-browser --cdp 9222 forward
```

### Recommended Navigation Pattern
```bash
# Different URL task: open a new tab first
agent-browser --auto-connect press "Control+L"
agent-browser --auto-connect press "Control+T"
agent-browser --auto-connect open https://example.com

# Same URL task: stay in current tab and refresh
agent-browser --auto-connect press F5
```

### Snapshot (Always use -i --json)
```bash
agent-browser --auto-connect snapshot -i --json
agent-browser --cdp 9222 snapshot -i -c -d 5 --json
```

### Interactions (Ref-based)
```bash
# Click after CDP connection
agent-browser --auto-connect click @e2
agent-browser --cdp 9222 fill @e3 "text"
agent-browser --auto-connect type @e3 "text"
```

### Wait
```bash
agent-browser --auto-connect wait --load networkidle
agent-browser --cdp 9222 wait @e2
agent-browser --auto-connect wait --text "Loaded"
```

### Get Information
```bash
agent-browser --auto-connect get text @e1 --json
agent-browser --cdp 9222 get title --json
agent-browser --auto-connect get url --json
```

### Screenshots & PDFs
```bash
agent-browser --auto-connect screenshot page.png
agent-browser --cdp 9222 screenshot --full page.png
agent-browser --auto-connect pdf page.pdf
```

### State Persistence
```bash
# Save state from CDP-connected browser
agent-browser --auto-connect state save auth.json

# Load state into new session
agent-browser --cdp 9222 state load auth.json
```

## Environment Variables (Optional)

```bash
# Set default CDP port (avoids repeating --cdp)
export AGENT_BROWSER_CDP_PORT=9222

# Now just use
agent-browser snapshot -i --json

# Set default auto-connect behavior
export AGENT_BROWSER_AUTO_CONNECT=true
```

## Best Practices (CDP-First)

1. **Always try CDP first** - Use `--auto-connect` or `--cdp 9222`
2. **Check CDP availability** - Verify port 9222 before connecting
3. **Always use persistent user-data-dir when launching manually**
4. **Handle connection failure** - Fall back to launching new browser if CDP unavailable
5. **Use --headed for debugging** - See what's happening in user's browser
6. **Respect user's browser** - Don't close user's main browser window
7. **Use isolated tabs** - Open new tabs instead of reusing user's active tab
8. **Different URL = new tab** - Avoid hijacking an old tab for a new task
9. **Same URL = reuse tab** - Refresh and continue in place when context is unchanged

## Example: Google Search (CDP-First)

```bash
# 1. Connect to existing browser
agent-browser --auto-connect open https://www.google.com

# 2. Wait for load
agent-browser --auto-connect wait --load networkidle

# 3. Snapshot to find search box
agent-browser --auto-connect snapshot -i --json

# 4. Fill and search
agent-browser --auto-connect fill @e1 "AI agents"
agent-browser --auto-connect press Enter

# 5. Wait for results
agent-browser --auto-connect wait --load networkidle

# 6. Extract results
agent-browser --auto-connect snapshot -i --json
agent-browser --auto-connect get text @e3 --json
```

## Example: Tab Reuse Strategy

```bash
# Case 1: Same URL, continue in current tab
agent-browser --auto-connect get url --json
agent-browser --auto-connect press F5
agent-browser --auto-connect wait --load networkidle

# Case 2: Different URL, open a new tab
agent-browser --auto-connect press "Control+T"
agent-browser --auto-connect open https://news.ycombinator.com
agent-browser --auto-connect wait --load networkidle
```

## Example: Multi-Session (Mixed CDP + New)

```bash
# CDP session (user's browser)
agent-browser --auto-connect --session user open app.com
agent-browser --auto-connect --session user snapshot -i --json

# Isolated session (new browser)
agent-browser --session admin open app.com
agent-browser --session admin snapshot -i --json
```

## Example: CDP Connection Check

```bash
# Helper script to check and connect
#!/bin/bash
if netstat -ano | findstr :9222 > /dev/null; then
    echo "CDP browser detected, connecting..."
    agent-browser --auto-connect "$@"
else
    echo "No CDP browser found, launching new..."
    agent-browser "$@"
fi
```

## Troubleshooting CDP

### CDP Connection Fails

```bash
# Check if CDP port is listening
curl http://127.0.0.1:9222/json/version

# If fails, restart browser with CDP and persistent profile
Stop-Process -Name msedge -Force
& "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --remote-debugging-port=9222 --user-data-dir="D:\temp\chrome-debug"
```

### Browser Already Running Without CDP

```bash
# Solution 1: Close and restart with CDP
# Solution 2: Use different CDP port
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9223 --user-data-dir="D:\temp\chrome-debug"

agent-browser --cdp 9223 snapshot -i --json
```

### Multiple Browser Instances

```bash
# Check which process is using port 9222
netstat -ano | findstr :9222

# Kill specific PID if needed
taskkill /PID <PID> /F
```

## Comparison: CDP vs New Browser

| Feature | CDP Connection | New Browser |
|---------|---------------|-------------|
| Speed | ⚡ Fast (instant) | 🐢 Slow (startup) |
| Login State | ✅ Preserved | ❌ Fresh |
| Extensions | ✅ Available | ❌ None |
| Resources | ✅ Shared | ❌ Duplicate |
| Isolation | ❌ Shared | ✅ Complete |
| Reliability | ⚠️ Depends on user | ✅ Guaranteed |

## Advanced: Dynamic Port Detection

```bash
# Find Chrome CDP port automatically
CHROME_PID=$(tasklist | findstr chrome.exe | awk '{print $2}' | head -1)
CDP_PORT=$(netstat -ano | findstr $CHROME_PID | findstr LISTENING | awk '{print $2}' | head -1)

if [ -n "$CDP_PORT" ]; then
    agent-browser --cdp $CDP_PORT "$@"
else
    agent-browser "$@"
fi
```

## Installation

```bash
npm install -g agent-browser
agent-browser install                     # Download Chromium (fallback)
```

## Quick Reference

```bash
# CDP Connection (Priority)
agent-browser --auto-connect <command>    # Auto-discover
agent-browser --cdp 9222 <command>       # Specific port
agent-browser --cdp http://127.0.0.1:9222 <command>  # Full URL

# New Browser (Fallback)
agent-browser <command>                  # No CDP flags

# Environment Variables
export AGENT_BROWSER_CDP_PORT=9222        # Default port
export AGENT_BROWSER_AUTO_CONNECT=true    # Always auto-connect

# Common Patterns
agent-browser --auto-connect snapshot -i --json
agent-browser --cdp 9222 open https://example.com
agent-browser --auto-connect wait --load networkidle
```

## Credits

**Skill created by:** Yossi Elkrief (@MaTriXy)
**agent-browser CLI by:** Vercel Labs
**CDP-First modifications:** OpenClaw Community (2026)

---

## Decision Flow for AI Agents

When the user asks for browser automation:

1. **First**: Check if browser with CDP is running
   - Test: `curl http://127.0.0.1:9222/json/version`
   
2. **If available**: Use CDP connection
   - Command: `agent-browser --auto-connect <command>`
   
3. **If unavailable**: Offer options
   - Ask user to start browser with CDP
   - Or launch new browser as fallback
   
4. **Execute**: Perform automation with CDP flags

Additional tab rule:
- If the target is a different URL or a different site, open a new tab before navigation
- If the target is the same URL, stay in the current tab and refresh if necessary

This approach maximizes efficiency and user experience while preserving login sessions across runs.
