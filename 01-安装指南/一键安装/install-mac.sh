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
NODE_MIN_MINOR="22"
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

    # 清除 .npmrc 中的 prefix/globalconfig（与 nvm 冲突）
    local user_npmrc="$HOME/.npmrc"
    if [[ -f "$user_npmrc" ]]; then
        sed -i.bak '/^prefix=/d;/^globalconfig=/d' "$user_npmrc" 2>/dev/null || true
        rm -f "${user_npmrc}.bak" 2>/dev/null
    fi

    # 加载 nvm
    export NVM_DIR
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" || true

    if command -v node &>/dev/null; then
        NODE_VER=$(node -v)
        ok "检测到 Node.js: ${NODE_VER}"
        if check_node_ver; then
            ok "版本检查通过（要求 v${NODE_MIN_MAJOR}.${NODE_MIN_MINOR}+）"
            _configure_git_https
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

    # 版本仍不够时固定安装 22.22.1
    if ! check_node_ver; then
        warn "nvm 安装了 $(node -v)，版本仍不足，固定安装 22.22.1..."
        nvm install 22.22.1 >> "$LOG" 2>&1
        nvm use 22.22.1 >> "$LOG" 2>&1
    fi

    NODE_VER=$(node -v)
    ok "Node.js ${NODE_VER} 就绪"
}

# ============================================================
#  Configure git to use HTTPS (prevent SSH host key failures)
# ============================================================
_configure_git_https() {
    if command -v git &>/dev/null; then
        git config --global url."https://github.com/".insteadOf "git@github.com:"
        git config --global url."https://".insteadOf "git://"
        ok "git 已配置为 HTTPS 访问（防止 SSH 错误）"
    fi
}

# ============================================================
#  Step 3 - Configure npm registry (permanent)
# ============================================================
step3_configure_npm() {
    step 3 "配置 npm 和 git"

    local user_npmrc="$HOME/.npmrc"

    # 安全更新 .npmrc：仅修改 registry（和可选 prefix），保留用户已有配置
    if [[ -f "$user_npmrc" ]]; then
        # 移除旧的 registry 行（稍后追加新值）
        sed -i.bak '/^registry=/d' "$user_npmrc" 2>/dev/null || true
        rm -f "${user_npmrc}.bak" 2>/dev/null
    fi

    # nvm 环境下只写 registry，不写 prefix（prefix 由 nvm 管理，写入会冲突）
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        echo "registry=${BEST_NPM_MIRROR}" >> "$user_npmrc"
        ok "已更新: ${user_npmrc}（registry=${BEST_NPM_MIRROR}，prefix 由 nvm 管理）"
    else
        # 非 nvm 环境才需要手动指定 prefix
        local npm_prefix
        npm_prefix=$(npm prefix -g 2>/dev/null || echo "$HOME/.npm-global")
        sed -i.bak '/^prefix=/d' "$user_npmrc" 2>/dev/null || true
        rm -f "${user_npmrc}.bak" 2>/dev/null
        {
            echo "registry=${BEST_NPM_MIRROR}"
            echo "prefix=${npm_prefix}"
        } >> "$user_npmrc"
        ok "已更新: ${user_npmrc}（registry + prefix）"
        info "npm 全局安装目录: ${npm_prefix}"
    fi

    _configure_git_https
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

    # 写入/更新 Node 镜像环境变量
    if grep -q "NVM_NODEJS_ORG_MIRROR" "$SHELL_RC" 2>/dev/null; then
        # 已存在则更新值（镜像可能在重跑时变化）
        sed -i.bak '/NVM_NODEJS_ORG_MIRROR/d' "$SHELL_RC" 2>/dev/null || true
        rm -f "${SHELL_RC}.bak" 2>/dev/null
    fi
    echo "export NVM_NODEJS_ORG_MIRROR=\"${BEST_NODE_MIRROR}\"  # OpenClaw 安装脚本" \
        >> "$SHELL_RC"
    ok "NVM_NODEJS_ORG_MIRROR 已写入 ${SHELL_RC}（${BEST_NODE_NAME}）"
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
        npm update -g openclaw --registry "${BEST_NPM_MIRROR}" --loglevel http 2>&1 | tee -a "$LOG" || true
        return 0
    fi
    info "正在执行: npm install -g openclaw@latest（进度显示如下）"
    npm install -g openclaw@latest --registry "${BEST_NPM_MIRROR}" --loglevel http 2>&1 | tee -a "$LOG" || {
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

    # 重载 nvm 环境（不能 source .zshrc，因为当前是 bash 进程，zsh 语法会导致崩溃）
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" 2>/dev/null || true

    # 重建 PATH：覆盖所有可能的全局 bin 路径
    local npm_bin nvm_bin pnpm_bin pnpm_home

    # 1. nvm 当前版本的 bin 目录（最关键）
    if command -v node &>/dev/null; then
        nvm_bin="$(dirname "$(command -v node)")"
        [[ -d "$nvm_bin" ]] && export PATH="${nvm_bin}:${PATH}"
        info "Node bin: ${nvm_bin}"
    fi

    # 2. npm 全局 prefix/bin
    npm_bin="$(npm prefix -g 2>/dev/null)/bin"
    [[ -d "$npm_bin" ]] && export PATH="${npm_bin}:${PATH}"
    info "npm  bin: ${npm_bin}"

    # 3. pnpm 全局 bin
    pnpm_bin="$(pnpm bin -g 2>/dev/null)" || pnpm_bin=""
    [[ -n "$pnpm_bin" && -d "$pnpm_bin" ]] && export PATH="${pnpm_bin}:${PATH}"

    # 4. pnpm home
    pnpm_home="${PNPM_HOME:-$HOME/.local/share/pnpm}"
    [[ -d "$pnpm_home" ]] && export PATH="${pnpm_home}:${PATH}"

    if ! command -v openclaw &>/dev/null; then
        err "openclaw 命令未找到"
        echo
        info "路径诊断:"
        local scan_dirs=(
            "${nvm_bin:-}"
            "${npm_bin:-}"
            "${pnpm_bin:-}"
            "$pnpm_home"
            "$HOME/.npm-global/bin"
        )
        for dir in "${scan_dirs[@]}"; do
            if [[ -n "$dir" && -f "$dir/openclaw" ]]; then
                echo -e "  ${GREEN}Found:${NC} $dir/openclaw"
                warn "文件存在但不在 PATH 中，尝试手动添加..."
                export PATH="$dir:$PATH"
            elif [[ -n "$dir" && -d "$dir" ]]; then
                echo -e "  ${GRAY}Scanned (not found):${NC} $dir"
            fi
        done
        echo

        # 全局搜索 openclaw 可执行文件
        local found_path=""
        found_path=$(find "$HOME/.nvm" "$HOME/.npm-global" "$HOME/.local" -name "openclaw" -type f -perm +111 2>/dev/null | head -1) || true
        if [[ -n "$found_path" ]]; then
            warn "全局搜索发现: ${found_path}"
            local found_dir
            found_dir="$(dirname "$found_path")"
            export PATH="$found_dir:$PATH"
            info "已临时添加到 PATH: $found_dir"
        fi

        # 再次尝试
        if ! command -v openclaw &>/dev/null; then
            local npm_global_dir
            npm_global_dir="$(npm prefix -g 2>/dev/null)/lib/node_modules/openclaw"
            if [[ -d "$npm_global_dir" ]]; then
                warn "包已安装在 ${npm_global_dir}，但 bin 链接可能缺失"
                info "修复方式: npm install -g openclaw@latest --force"
            fi
            echo
            err "请尝试: source ${SHELL_RC} && openclaw --version"
            err "或者重新打开一个终端窗口"
            exit 1
        fi
    fi

    OC_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    ok "openclaw ${OC_VERSION} 已就绪"
    log "openclaw 版本: ${OC_VERSION}"
}

# ============================================================
#  第 7 步 - 初始化 + 启动网关 + 配置开机自启动
# ============================================================
GATEWAY_PORT=18789

# 检测 Gateway 端口是否在监听
_check_gateway_port() {
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

# 轮询等待 Gateway 就绪
_wait_gateway() {
    local max_wait=30 poll_interval=2 elapsed=0
    info "等待 Gateway 就绪（最多 ${max_wait} 秒）..."
    while [[ $elapsed -lt $max_wait ]]; do
        if _check_gateway_port; then
            echo
            ok "Gateway 启动成功！端口 ${GATEWAY_PORT} 已监听（耗时 ${elapsed}s）"
            openclaw gateway status 2>/dev/null || true
            return 0
        fi
        printf "\r${CYAN}[ INFO ]${NC} 等待中... %ds / %ds" "$elapsed" "$max_wait"
        sleep "$poll_interval"
        elapsed=$((elapsed + poll_interval))
    done
    echo
    warn "Gateway 启动超时（${max_wait}s），请手动检查:"
    warn "  openclaw gateway logs"
    warn "  openclaw gateway status"
    return 1
}

step7_init_and_autostart() {
    step 7 "初始化配置 + 安装 Gateway 服务 + 开机自启动"

    # ---- 7.1 初始化 OpenClaw ----
    info "Step 7.1: 初始化 OpenClaw 配置"
    read -r -p "是否立即初始化 OpenClaw？ [Y/N]: " DO_INIT
    if [[ "$DO_INIT" =~ ^[Yy]$ ]]; then
        echo
        info "正在执行: openclaw init"
        openclaw init || warn "初始化未完成，可稍后手动执行: openclaw init"
        echo
    else
        info "跳过初始化（后续可执行: openclaw init）"
    fi

    # ---- 7.2 安装并启动 Gateway 服务 ----
    echo
    info "Step 7.2: 安装 Gateway 服务（LaunchAgent）"

    # 清理脚本旧版本手动创建的 plist（标签不匹配，会冲突）
    local old_plist="$HOME/Library/LaunchAgents/com.openclaw.gateway.plist"
    if [[ -f "$old_plist" ]]; then
        launchctl unload "$old_plist" 2>/dev/null || true
        rm -f "$old_plist"
        info "已清理旧版 plist: ${old_plist}"
    fi

    if _check_gateway_port; then
        ok "Gateway 已在运行（端口 ${GATEWAY_PORT}）"
    else
        read -r -p "是否安装并启动 Gateway 服务？ [Y/N]: " DO_INSTALL
        if [[ "$DO_INSTALL" =~ ^[Yy]$ ]]; then
            echo
            # openclaw gateway install: 安装 LaunchAgent + 启动服务 + 开机自启动（一步到位）
            info "正在执行: openclaw gateway install"
            openclaw gateway install 2>&1 || {
                warn "openclaw gateway install 失败，尝试备用方式..."
                # 备用: 使用 launchctl bootstrap 手动加载
                local plist="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
                if [[ -f "$plist" ]]; then
                    info "尝试: launchctl bootstrap gui/\$(id -u) ${plist}"
                    launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null || true
                fi
            }
            echo
            _wait_gateway
        else
            info "跳过安装（后续可执行: openclaw gateway install）"
        fi
    fi

    # ---- 7.3 验证 Gateway 服务状态 ----
    echo
    info "Step 7.3: 验证 Gateway 服务"
    openclaw gateway status 2>/dev/null || true
}

# ============================================================
#  安装汇总
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
    echo "  常用命令:"
    echo "    source ${SHELL_RC}          # 重载 Shell 环境（新终端自动生效）"
    echo "    openclaw init               # 初始化配置"
    echo "    openclaw gateway install    # 安装 Gateway 服务（含开机自启动）"
    echo "    openclaw gateway status     # 查看 Gateway 状态"
    echo "    openclaw gateway logs       # 查看 Gateway 日志"
    echo "    openclaw status             # 查看全局状态"
    echo "    openclaw --help             # 查看所有命令"
    echo "============================================================"
    echo

    log
    log "安装完成: $(date)"
    log "OpenClaw: ${OC_VERSION}"

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
    step7_init_and_autostart
    summary
}

main "$@"
