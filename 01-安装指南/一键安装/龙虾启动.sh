#!/usr/bin/env bash
# ============================================================
#  OpenClaw Gateway - 检测 & 启动（macOS / Linux）
#  检测端口 18789 是否监听，未启动则自动启动并验证
# ============================================================

set -euo pipefail

GATEWAY_PORT=18789
MAX_WAIT=30
POLL_INTERVAL=2

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

ok()   { echo -e "${GREEN}[  OK  ]${NC} $*"; }
info() { echo -e "${CYAN}[ INFO ]${NC} $*"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $*"; }
err()  { echo -e "${RED}[ERROR ]${NC} $*" >&2; }

echo
echo "============================================================"
echo "  OpenClaw Gateway - Check & Start"
echo "============================================================"
echo

# ---- 检查 openclaw 命令是否可用 ----
if ! command -v openclaw &>/dev/null; then
    err "openclaw command not found"
    err "  Please run the install script first, or restart your terminal."
    err "  macOS:  source ~/.zshrc"
    err "  Linux:  source ~/.bashrc"
    exit 1
fi

# ---- 检测 Gateway 是否已在运行（端口监听检测）----
check_port() {
    if command -v lsof &>/dev/null; then
        lsof -iTCP:"${GATEWAY_PORT}" -sTCP:LISTEN -P -n &>/dev/null
    elif command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep -q ":${GATEWAY_PORT} "
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | grep -q ":${GATEWAY_PORT} "
    else
        return 1
    fi
}

info "Checking Gateway status (port ${GATEWAY_PORT})..."

if check_port; then
    ok "Gateway is already running, no need to start again"
    echo
    echo "  Port ${GATEWAY_PORT} is listening"
    echo
    openclaw gateway status 2>/dev/null || true
    echo
    exit 0
fi

# ---- Gateway 未运行，执行启动 ----
warn "Gateway is not running, starting..."
echo

# 优先使用 gateway install（安装 LaunchAgent 并启动），失败则回退到 gateway start
if openclaw gateway install 2>&1; then
    info "Gateway service installed via LaunchAgent"
else
    warn "gateway install failed, trying direct start..."
    openclaw gateway start &
fi
echo

# ---- 轮询等待进程就绪（最多 MAX_WAIT 秒）----
info "Waiting for Gateway to become ready (up to ${MAX_WAIT} seconds)..."
ELAPSED=0

while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    if check_port; then
        echo
        ok "Gateway started successfully! Port ${GATEWAY_PORT} is listening (elapsed ${ELAPSED}s)"
        echo
        openclaw gateway status 2>/dev/null || true
        echo
        exit 0
    fi

    REMAINING=$((MAX_WAIT - ELAPSED))
    printf "\r${CYAN}[ INFO ]${NC} Waiting... elapsed %ds / %ds" "$ELAPSED" "$MAX_WAIT"
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

# ---- 超时 ----
echo
err "Gateway startup timed out. Port ${GATEWAY_PORT} did not start listening within ${MAX_WAIT} seconds"
echo
echo "  Troubleshooting suggestions:"
echo "    1. View logs: openclaw gateway logs"
echo "    2. Start manually: openclaw gateway start"
echo "    3. Check status: openclaw gateway status"
echo
exit 1
