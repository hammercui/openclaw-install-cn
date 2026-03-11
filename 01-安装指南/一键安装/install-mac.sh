#!/usr/bin/env bash
# ============================================================
#  OpenClaw 一键安装脚本（macOS）
#  版本: 2.1.0
#  内地网络优化版
# ============================================================

set -euo pipefail

VERSION="2.1.0"
NODE_TARGET="22"
NODE_MIN_MAJOR="22"
NODE_MIN_MINOR="12"
LOG="/tmp/openclaw-install-mac.log"
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

SHELL_RC="$HOME/.zshrc"
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
    echo -e "${CYAN}---- 第 $1 步/共 7 步: $2 ----${NC}"
    log
    log "---- 第 $1 步/共 7 步: $2 ----"
}

header() {
    echo
    echo "============================================================"
    echo "  OpenClaw 一键安装脚本（macOS）  v${VERSION}"
    echo "  日志文件: ${LOG}"
    echo "============================================================"
    echo
}

# ============================================================
#  Test a single mirror, return latency in ms
# ============================================================
test_mirror() {
    local url="$1"
    local raw
    raw=$(curl -s -o /dev/null --connect-timeout 4 --max-time 6 \
        -w "%{time_total}" "$url" 2>/dev/null) || raw="9.999"
    # Convert seconds (e.g. "0.253") to integer ms
    echo "$raw" | awk '{printf "%d", $1 * 1000}'
}

# ============================================================
#  Check if current node version meets minimum requirement
# ============================================================
check_node_ver() {
    local major minor
    major=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
    minor=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f2)
    [[ -z "$major" ]] && return 1
    [[ $major -gt $NODE_MIN_MAJOR ]] && return 0
    [[ $major -eq $NODE_MIN_MAJOR && $minor -ge $NODE_MIN_MINOR ]] && return 0
    return 1
}

# ============================================================
#  Step 1 - Test mirrors and select fastest
# ============================================================
step1_test_mirrors() {
    step 1 "测试镜像速度"

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

    info "正在测试 npm 镜像速度..."
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
    ok "npm 镜像: ${BEST_NPM_NAME} (${BEST_NPM_MIRROR}) - ${BEST_NPM_MS}ms"

    info "正在测试 Node.js 下载镜像速度..."
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
    ok "Node 镜像: ${BEST_NODE_NAME} (${BEST_NODE_MIRROR}) - ${BEST_NODE_MS}ms"
}

# ============================================================
#  Detect shell config file
# ============================================================
detect_shell_rc() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        SHELL_RC="$HOME/.bash_profile"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
    info "当前 Shell 配置文件: ${SHELL_RC}"
}

# ============================================================
#  第 2 步 - 检查 / 安装 Node.js
# ============================================================
step2_check_nodejs() {
    step 2 "检查 Node.js（要求 v${NODE_MIN_MAJOR}.${NODE_MIN_MINOR}+）"

    detect_shell_rc

    # 加载 nvm
    export NVM_DIR
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" || true

    if command -v node &>/dev/null; then
        NODE_VER=$(node -v)
        ok "检测到 Node.js: ${NODE_VER}"
        if check_node_ver; then
            ok "版本模算通过（要求 v${NODE_MIN_MAJOR}.${NODE_MIN_MINOR}+）"
            return 0
        else
            warn "${NODE_VER} 版本过低，将进行升级..."
        fi
    else
        info "未安装 Node.js，开始安装..."
    fi

    # 确保 git 可用
    if ! command -v git &>/dev/null; then
        err "git 未找到，请先安装 Xcode 命令行工具:"
        err "  xcode-select --install"
        exit 1
    fi

    # 安装 nvm
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        info "正在从 Gitee 镜像安装 nvm..."
        git clone --depth=1 "$NVM_GITEE" "$NVM_DIR" >> "$LOG" 2>&1 || {
            err "nvm 克隆失败，详情请查看日志: ${LOG}"
            exit 1
        }
        ok "nvm 安装完成（来自 Gitee 镜像）"
    fi
    source "$NVM_DIR/nvm.sh"

    info "正在安装 Node.js ${NODE_TARGET}（镜像: ${BEST_NODE_NAME}）..."
    export NVM_NODEJS_ORG_MIRROR="$BEST_NODE_MIRROR"
    nvm install "${NODE_TARGET}" >> "$LOG" 2>&1
    nvm use "${NODE_TARGET}" >> "$LOG" 2>&1
    nvm alias default "${NODE_TARGET}" >> "$LOG" 2>&1

    # 版本仍不够时固定安装 22.12.0
    if ! check_node_ver; then
        warn "nvm 安装了 $(node -v)，版本仍不足，固定安装 22.12.0..."
        nvm install 22.12.0 >> "$LOG" 2>&1
        nvm use 22.12.0 >> "$LOG" 2>&1
    fi

    NODE_VER=$(node -v)
    ok "Node.js ${NODE_VER} 就绪"
}

# ============================================================
#  Step 3 - Configure npm registry (permanent)
# ============================================================
step3_configure_npm() {
    step 3 "配置 npm 和 git"

    # 直接写 .npmrc（避免 npm config set 卡死）
    local npm_prefix
    npm_prefix=$(npm prefix -g 2>/dev/null || echo "$HOME/.npm-global")
    local user_npmrc="$HOME/.npmrc"
    {
        echo "registry=${BEST_NPM_MIRROR}"
        echo "prefix=${npm_prefix}"
    } > "$user_npmrc"
    ok "已写入: ${user_npmrc}（registry + prefix）"
    info "npm 全局安装目录: ${npm_prefix}"

    # 将 git 的 SSH 协议强制转为 HTTPS，避免 SSH host key 验证失败
    if command -v git &>/dev/null; then
        git config --global url."https://github.com/".insteadOf "git@github.com:"
        git config --global url."https://".insteadOf "git://"
        ok "git 已配置为 HTTPS 访问（防止 SSH 错误）"
    fi
}

# ============================================================
#  Step 4 - Configure shell environment (permanent)
# ============================================================
step4_configure_env() {
    step 4 "配置 Shell 环境变量"

    # 将 nvm 初始化代码写入 shell 配置文件
    if ! grep -q "NVM_DIR" "$SHELL_RC" 2>/dev/null; then
        {
            echo
            echo '# nvm（由 OpenClaw 安装脚本添加）'
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
        } >> "$SHELL_RC"
        ok "nvm 初始化代码已写入 ${SHELL_RC}"
    else
        info "nvm 已配置在 ${SHELL_RC} 中，跳过"
    fi

    # 写入 Node 镜像环境变量
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$SHELL_RC" 2>/dev/null; then
        echo "export NVM_NODEJS_ORG_MIRROR=\"${BEST_NODE_MIRROR}\"  # OpenClaw 安装脚本" \
            >> "$SHELL_RC"
        ok "NVM_NODEJS_ORG_MIRROR 已写入 ${SHELL_RC}"
    fi
}

# ============================================================
#  Step 5 - Install OpenClaw
# ============================================================
step5_install_openclaw() {
    step 5 "安装 OpenClaw"

    info "当前 npm 镜像: ${BEST_NPM_MIRROR}"

    # 安装 pnpm（处理 git/二进制依赖更可靠）
    if ! command -v pnpm &>/dev/null; then
        info "正在安装 pnpm..."
        if npm install -g pnpm --registry "${BEST_NPM_MIRROR}" >> "$LOG" 2>&1; then
            pnpm setup >> "$LOG" 2>&1 || true
            export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
            [[ -d "$PNPM_HOME" ]] && export PATH="$PNPM_HOME:$PATH"
            ok "pnpm 安装完成"
        else
            warn "pnpm 安装失败，将使用 npm 安装"
        fi
    fi

    # 优先使用 pnpm
    if command -v pnpm &>/dev/null; then
        if command -v openclaw &>/dev/null; then
            info "OpenClaw 已安装，升级中（pnpm）..."
            pnpm update -g openclaw >> "$LOG" 2>&1 || true
            return 0
        fi
        info "正在执行: pnpm install -g openclaw@latest --force"
        if pnpm install -g openclaw@latest --force 2>&1 | tee -a "$LOG"; then
            ok "OpenClaw 安装成功（pnpm）"
            return 0
        fi
        warn "pnpm 安装失败，回退到 npm"
    fi

    # npm 备用
    if command -v openclaw &>/dev/null; then
        info "OpenClaw 已安装，升级中（npm）..."
        npm update -g openclaw --registry "${BEST_NPM_MIRROR}" >> "$LOG" 2>&1 || true
        return 0
    fi
    info "正在执行: npm install -g openclaw@latest"
    npm install -g openclaw@latest --registry "${BEST_NPM_MIRROR}" >> "$LOG" 2>&1 || {
        err "OpenClaw 安装失败"
        err "  1. 检查 git: command -v git"
        err "  2. 测试镜像: curl ${BEST_NPM_MIRROR}"
        err "  3. 完整日志: ${LOG}"
        exit 1
    }
    ok "OpenClaw 安装成功（npm）"
}

# ============================================================
#  Step 6 - Verify installation
# ============================================================
step6_verify() {
    step 6 "验证安装"

    # 将 npm / pnpm 全局 bin 目录刷入 PATH
    local npm_bin pnpm_bin
    npm_bin="$(npm prefix -g 2>/dev/null)/bin"
    pnpm_bin="$(pnpm bin -g 2>/dev/null)" || pnpm_bin=""
    [[ -d "$npm_bin" ]] && export PATH="${npm_bin}:${PATH}"
    [[ -n "$pnpm_bin" && -d "$pnpm_bin" ]] && export PATH="${pnpm_bin}:${PATH}"

    if ! command -v openclaw &>/dev/null; then
        err "openclaw 命令未找到"
        err "请尝试: source ${SHELL_RC} && openclaw --version"
        err "或者重新打开一个终端窗口"
        exit 1
    fi

    OC_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "openclaw ${OC_VERSION} 已就绪"
    log "openclaw 版本: ${OC_VERSION}"
}

# ============================================================
#  第 7 步 - 配置开机自启动（launchd）
# ============================================================
step7_autostart() {
    step 7 "配置开机自启动（可选）"

    read -r -p "是否配置 OpenClaw Gateway 开机自启动？ [Y/N]: " DO_AUTOSTART
    if [[ ! "$DO_AUTOSTART" =~ ^[Yy]$ ]]; then
        info "跳过自启动配置"
        return 0
    fi

    local agents_dir="$HOME/Library/LaunchAgents"
    local plist_file="$agents_dir/com.openclaw.gateway.plist"
    local openclaw_path
    openclaw_path=$(command -v openclaw)

    mkdir -p "$agents_dir"

    cat > "$plist_file" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>${openclaw_path}</string>
        <string>gateway</string>
        <string>start</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-gateway.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-gateway-error.log</string>
</dict>
</plist>
PLIST

    launchctl load "$plist_file" 2>/dev/null || true
    ok "LaunchAgent 已安装: ${plist_file}"
    info "卸载方式: launchctl unload ${plist_file} && rm ${plist_file}"
}

# ============================================================
#  安装汇总 + 可选初始化/启动
# ============================================================
summary() {
    echo
    echo "============================================================"
    echo "  安装完成！"
    echo "============================================================"
    echo
    echo "  OpenClaw    : ${OC_VERSION}"
    echo "  Node.js     : ${NODE_VER}"
    echo "  npm 镜像   : ${BEST_NPM_NAME} (${BEST_NPM_MIRROR})"
    echo "  Node 镜像  : ${BEST_NODE_NAME} (${BEST_NODE_MIRROR})"
    echo "  Shell 配置  : ${SHELL_RC}"
    echo "  日志文件  : ${LOG}"
    echo
    echo "  后续操作:"
    echo "    source ${SHELL_RC}          # 重载 Shell 环境"
    echo "    openclaw init               # 初始化配置"
    echo "    openclaw gateway start      # 启动网关"
    echo "    openclaw gateway status     # 查看网关状态"
    echo "    openclaw --help             # 查看所有命令"
    echo "============================================================"
    echo

    log
    log "安装完成: $(date)"
    log "OpenClaw: ${OC_VERSION}"

    read -r -p "现在是否初始化 OpenClaw？ [Y/N]: " DO_INIT
    if [[ "$DO_INIT" =~ ^[Yy]$ ]]; then
        echo
        info "正在执行: openclaw init"
        openclaw init
        echo
        read -r -p "现在是否启动网关？ [Y/N]: " DO_START
        if [[ "$DO_START" =~ ^[Yy]$ ]]; then
            info "正在启动网关..."
            openclaw gateway start &
            sleep 2
            openclaw gateway status
        fi
    fi

    echo
    echo "日志已保存到: ${LOG}"
    echo
}

# ============================================================
#  Main
# ============================================================
main() {
    header
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
