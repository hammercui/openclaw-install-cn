#!/usr/bin/env bash
# ============================================================
#  OpenClaw One-Click Installer for Linux
#  Version: 2.0.0
#  Optimized for China mainland network
#  Supports: Ubuntu / Debian / CentOS / RHEL / Fedora /
#            Arch Linux / openSUSE and more
# ============================================================

set -euo pipefail

VERSION="2.0.0"
NODE_TARGET="22"
LOG="/tmp/openclaw-install-linux.log"
NVM_DIR="$HOME/.nvm"
NVM_GITEE="https://gitee.com/mirrors/nvm.git"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'

# Default mirrors
BEST_NPM_MIRROR="https://registry.npmmirror.com"
BEST_NPM_NAME="Taobao"
BEST_NPM_MS=9999
BEST_NODE_MIRROR="https://npmmirror.com/mirrors/node"
BEST_NODE_NAME="Taobao"
BEST_NODE_MS=9999

PKG_MGR="unknown"
SHELL_RC="$HOME/.bashrc"
NODE_VER="unknown"
OC_VERSION="unknown"

# ============================================================
#  Logging helpers
# ============================================================
log()  { echo "$*" >> "$LOG"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $*"; log "[  OK  ] $*"; }
info() { echo -e "${CYAN}[ INFO ]${NC} $*"; log "[ INFO ] $*"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $*"; log "[ WARN ] $*"; }
err()  { echo -e "${RED}[ERROR ]${NC} $*" >&2; log "[ERROR ] $*"; }
step() {
    echo
    echo -e "${CYAN}---- Step $1 of 7: $2 ----${NC}"
    log
    log "---- Step $1 of 7: $2 ----"
}

header() {
    echo
    echo "============================================================"
    echo "  OpenClaw One-Click Installer for Linux  v${VERSION}"
    echo "  Log: ${LOG}"
    echo "============================================================"
    echo
}

# ============================================================
#  Detect package manager and shell rc
# ============================================================
detect_env() {
    # Package manager
    if   command -v apt-get &>/dev/null; then PKG_MGR="apt"
    elif command -v dnf     &>/dev/null; then PKG_MGR="dnf"
    elif command -v yum     &>/dev/null; then PKG_MGR="yum"
    elif command -v pacman  &>/dev/null; then PKG_MGR="pacman"
    elif command -v zypper  &>/dev/null; then PKG_MGR="zypper"
    fi
    info "Package manager: ${PKG_MGR}"

    # Shell rc file
    case "$SHELL" in
        */zsh)  SHELL_RC="$HOME/.zshrc" ;;
        */fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
        *)      SHELL_RC="$HOME/.bashrc" ;;
    esac
    info "Shell config : ${SHELL_RC}"
}

# Install a package using the detected package manager
pkg_install() {
    local pkg="$1"
    info "Installing system package: ${pkg}"
    case "$PKG_MGR" in
        apt)    sudo apt-get install -y "$pkg" >> "$LOG" 2>&1 ;;
        dnf)    sudo dnf install -y "$pkg"     >> "$LOG" 2>&1 ;;
        yum)    sudo yum install -y "$pkg"     >> "$LOG" 2>&1 ;;
        pacman) sudo pacman -S --noconfirm "$pkg" >> "$LOG" 2>&1 ;;
        zypper) sudo zypper install -y "$pkg"  >> "$LOG" 2>&1 ;;
        *)      err "Unknown package manager - please install '${pkg}' manually"; return 1 ;;
    esac
}

# ============================================================
#  Test a single mirror, return latency in ms
# ============================================================
test_mirror() {
    local url="$1"
    local raw
    raw=$(curl -s -o /dev/null --connect-timeout 4 --max-time 6 \
        -w "%{time_total}" "$url" 2>/dev/null) || raw="9.999"
    echo "$raw" | awk '{printf "%d", $1 * 1000}'
}

# ============================================================
#  Step 1 - Test mirrors and select fastest
# ============================================================
step1_test_mirrors() {
    step 1 "Testing mirror speed"

    # Ensure curl is available
    if ! command -v curl &>/dev/null; then
        warn "curl not found - installing..."
        pkg_install curl
    fi

    local npm_mirrors=(
        "https://registry.npmmirror.com|Taobao"
        "https://mirrors.cloud.tencent.com/npm/|Tencent"
        "https://mirrors.huaweicloud.com/repository/npm/|Huawei"
    )
    local node_mirrors=(
        "https://npmmirror.com/mirrors/node|Taobao"
        "https://mirrors.cloud.tencent.com/nodejs-release/|Tencent"
        "https://mirrors.huaweicloud.com/nodejs/|Huawei"
    )

    info "Testing npm mirrors..."
    for entry in "${npm_mirrors[@]}"; do
        local url="${entry%%|*}" name="${entry##*|}"
        local ms
        ms=$(test_mirror "$url")
        echo -e "  ${GRAY}${name}: ${ms}ms${NC}"
        log "  ${name}: ${ms}ms"
        if [[ $ms -lt $BEST_NPM_MS ]]; then
            BEST_NPM_MS=$ms; BEST_NPM_MIRROR="$url"; BEST_NPM_NAME="$name"
        fi
    done
    ok "npm mirror   : ${BEST_NPM_NAME} (${BEST_NPM_MIRROR}) - ${BEST_NPM_MS}ms"

    info "Testing Node.js download mirrors..."
    for entry in "${node_mirrors[@]}"; do
        local url="${entry%%|*}" name="${entry##*|}"
        local ms
        ms=$(test_mirror "$url")
        echo -e "  ${GRAY}${name}: ${ms}ms${NC}"
        log "  ${name}: ${ms}ms"
        if [[ $ms -lt $BEST_NODE_MS ]]; then
            BEST_NODE_MS=$ms; BEST_NODE_MIRROR="$url"; BEST_NODE_NAME="$name"
        fi
    done
    ok "Node mirror  : ${BEST_NODE_NAME} (${BEST_NODE_MIRROR}) - ${BEST_NODE_MS}ms"
}

# ============================================================
#  Step 2 - Check / Install Node.js via nvm
# ============================================================
step2_check_nodejs() {
    step 2 "Checking Node.js"

    # Load nvm if already installed
    export NVM_DIR
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" || true

    if command -v node &>/dev/null; then
        NODE_VER=$(node -v)
        ok "Node.js already installed: ${NODE_VER}"
        return 0
    fi

    info "Node.js not found, installing via nvm..."

    # Ensure git is available for nvm clone
    if ! command -v git &>/dev/null; then
        warn "git not found - installing..."
        pkg_install git
    fi

    # Install nvm if missing
    if ! command -v nvm &>/dev/null && [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        info "Installing nvm from Gitee mirror..."
        git clone --depth=1 "$NVM_GITEE" "$NVM_DIR" >> "$LOG" 2>&1 || {
            err "nvm clone failed - see log: ${LOG}"
            err "Manual: git clone ${NVM_GITEE} ~/.nvm"
            exit 1
        }
        ok "nvm installed from Gitee"
    fi

    source "$NVM_DIR/nvm.sh"

    # Install Node.js via nvm
    info "Installing Node.js ${NODE_TARGET} (mirror: ${BEST_NODE_NAME})..."
    export NVM_NODEJS_ORG_MIRROR="$BEST_NODE_MIRROR"
    nvm install "$NODE_TARGET" >> "$LOG" 2>&1
    nvm use "$NODE_TARGET" >> "$LOG" 2>&1
    nvm alias default "$NODE_TARGET" >> "$LOG" 2>&1

    NODE_VER=$(node -v)
    ok "Node.js ${NODE_VER} installed via nvm"
}

# ============================================================
#  Step 3 - Configure npm registry (permanent)
# ============================================================
step3_configure_npm() {
    step 3 "Configuring npm registry (permanent)"

    npm config set registry "$BEST_NPM_MIRROR" >> "$LOG" 2>&1
    ok "npm config set registry -> ${BEST_NPM_NAME}"

    local user_npmrc="$HOME/.npmrc"
    echo "registry=${BEST_NPM_MIRROR}" > "$user_npmrc"
    ok "Written: ${user_npmrc}"

    info "Registry config is permanent - survives terminal restarts"
}

# ============================================================
#  Step 4 - Configure shell environment (permanent)
# ============================================================
step4_configure_env() {
    step 4 "Configuring shell environment"

    # Add nvm init to shell rc if not present
    if ! grep -q "NVM_DIR" "$SHELL_RC" 2>/dev/null; then
        {
            echo
            echo '# nvm (added by OpenClaw installer)'
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
        } >> "$SHELL_RC"
        ok "nvm init added to ${SHELL_RC}"
    else
        info "nvm already configured in ${SHELL_RC}"
    fi

    # Add NODE_MIRROR if not present
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$SHELL_RC" 2>/dev/null; then
        echo "export NVM_NODEJS_ORG_MIRROR=\"${BEST_NODE_MIRROR}\"  # OpenClaw installer" \
            >> "$SHELL_RC"
        ok "NVM_NODEJS_ORG_MIRROR set in ${SHELL_RC}"
    fi
}

# ============================================================
#  Step 5 - Install OpenClaw
# ============================================================
step5_install_openclaw() {
    step 5 "Installing OpenClaw"

    info "Registry: ${BEST_NPM_MIRROR}"

    if npm list -g openclaw &>/dev/null; then
        info "OpenClaw already installed - updating..."
        npm update -g openclaw >> "$LOG" 2>&1
    else
        npm install -g openclaw >> "$LOG" 2>&1
    fi

    if ! npm list -g openclaw &>/dev/null; then
        err "OpenClaw installation failed"
        err "Troubleshooting:"
        err "  1. Check network: curl ${BEST_NPM_MIRROR}"
        err "  2. Retry: npm install -g openclaw"
        err "  3. Full log: ${LOG}"
        exit 1
    fi

    ok "OpenClaw installed"
}

# ============================================================
#  Step 6 - Verify installation
# ============================================================
step6_verify() {
    step 6 "Verifying installation"

    # Reload PATH (nvm adds npm global bin)
    export PATH="$PATH:$(npm bin -g 2>/dev/null || true)"

    if ! command -v openclaw &>/dev/null; then
        err "openclaw command not found"
        err "Reload shell config: source ${SHELL_RC}"
        err "Or open a new terminal session"
        exit 1
    fi

    OC_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "openclaw ${OC_VERSION} is ready"
    log "openclaw version: ${OC_VERSION}"
}

# ============================================================
#  Step 7 - Auto-start via systemd / crontab (optional)
# ============================================================
step7_autostart() {
    step 7 "Auto-start configuration (optional)"

    read -r -p "Configure OpenClaw Gateway to auto-start at login? [Y/N]: " DO_AUTOSTART
    if [[ ! "$DO_AUTOSTART" =~ ^[Yy]$ ]]; then
        info "Skipping auto-start"
        return 0
    fi

    local openclaw_path
    openclaw_path=$(command -v openclaw)

    # Try systemd user service (preferred)
    if command -v systemctl &>/dev/null && systemctl --user status &>/dev/null 2>&1; then
        local service_dir="$HOME/.config/systemd/user"
        local service_file="$service_dir/openclaw-gateway.service"

        mkdir -p "$service_dir"
        cat > "$service_file" << SERVICE
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=${openclaw_path} gateway start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
SERVICE

        systemctl --user daemon-reload
        systemctl --user enable openclaw-gateway.service >> "$LOG" 2>&1
        systemctl --user start  openclaw-gateway.service >> "$LOG" 2>&1 || true

        ok "systemd user service installed and enabled"
        info "  Status : systemctl --user status openclaw-gateway"
        info "  Stop   : systemctl --user stop openclaw-gateway"
        info "  Disable: systemctl --user disable openclaw-gateway"
        return 0
    fi

    # Fallback: crontab @reboot
    warn "systemd user session not available - using crontab @reboot"
    local cron_entry="@reboot ${openclaw_path} gateway start"
    ( crontab -l 2>/dev/null | grep -v "openclaw gateway start"; echo "$cron_entry" ) | crontab -
    ok "crontab @reboot entry added"
    info "To remove: crontab -e  (delete the @reboot openclaw line)"
}

# ============================================================
#  Summary + optional init/start
# ============================================================
summary() {
    echo
    echo "============================================================"
    echo "  Installation Complete!"
    echo "============================================================"
    echo
    echo "  OpenClaw    : ${OC_VERSION}"
    echo "  Node.js     : ${NODE_VER}"
    echo "  npm mirror  : ${BEST_NPM_NAME} (${BEST_NPM_MIRROR})"
    echo "  Node mirror : ${BEST_NODE_NAME} (${BEST_NODE_MIRROR})"
    echo "  Shell config: ${SHELL_RC}"
    echo "  Log file    : ${LOG}"
    echo
    echo "  Next steps:"
    echo "    source ${SHELL_RC}          # Reload shell"
    echo "    openclaw init               # Initialize configuration"
    echo "    openclaw gateway start      # Start the Gateway"
    echo "    openclaw gateway status     # Check status"
    echo "    openclaw --help             # Show all commands"
    echo "============================================================"
    echo

    log
    log "Installation Complete: $(date)"
    log "OpenClaw: ${OC_VERSION}"

    read -r -p "Initialize OpenClaw now? [Y/N]: " DO_INIT
    if [[ "$DO_INIT" =~ ^[Yy]$ ]]; then
        echo
        info "Running: openclaw init"
        openclaw init
        echo
        read -r -p "Start Gateway now? [Y/N]: " DO_START
        if [[ "$DO_START" =~ ^[Yy]$ ]]; then
            info "Starting Gateway..."
            openclaw gateway start &
            sleep 2
            openclaw gateway status
        fi
    fi

    echo
    echo "Log saved to: ${LOG}"
    echo
}

# ============================================================
#  Main
# ============================================================
main() {
    header
    detect_env
    step1_test_mirrors
    step2_check_nodejs
    step3_configure_npm
    step4_configure_env
    step5_install_openclaw
    step6_verify
    step7_autostart
    summary
}

main "$@"
