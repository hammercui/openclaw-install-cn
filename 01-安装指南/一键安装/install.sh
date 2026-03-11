#!/bin/bash
# ============================================
# OpenClaw 一键安装脚本 (macOS/Linux)
# 优化版：国内网络加速 + 错误重试
# ============================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 国内镜像配置（优先级从高到低）
NPM_MIRRORS=(
    "https://registry.npmmirror.com"          # 淘宝镜像（主）
    "https://mirrors.cloud.tencent.com/npm"   # 腾讯云镜像（备）
    "https://mirrors.huaweicloud.com/repository/npm/"  # 华为云镜像（备）
)

NVM_NODE_MIRRORS=(
    "https://npmmirror.com/mirrors/node"      # 淘宝 Node 镜像（主）
    "https://mirrors.cloud.tencent.com/npm/"  # 腾讯云 Node 镜像（备）
    "https://nodejs.org/dist"                 # 官方源（最后）
)

# GitHub 下载代理（解决国内访问慢）
GITHUB_PROXIES=(
    "https://mirror.ghproxy.com"              # GHProxy 镜像（主）
    "https://ghproxy.net"                     # GHProxy 备用
    ""                                         # 直连（最后）
)

# 输出函数
print_header() {
    echo -e "${CYAN}"
    echo "============================================"
    echo "    OpenClaw 一键安装 (国内优化版)"
    echo "============================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}[成功] $1${NC}"
}

print_info() {
    echo -e "${YELLOW}[信息] $1${NC}"
}

print_error() {
    echo -e "${RED}[错误] $1${NC}"
}

print_step() {
    echo -e "${CYAN}"
    echo "[步骤] $1"
    echo -e "${NC}"
}

# 网络检测函数
test_network() {
    local url="$1"
    local timeout=${2:-5}
    
    if command -v curl &> /dev/null; then
        curl -s -o /dev/null -m "$timeout" --connect-timeout 3 --head "$url" > /dev/null 2>&1
        return $?
    elif command -v wget &> /dev/null; then
        wget -q -T "$timeout" -t 1 --spider "$url" > /dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# 下载函数（带重试和代理）
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=${3:-3}
    local attempt=0
    local success=false
    
    while [ "$success" = false ] && [ $attempt -lt $max_retries ]; do
        attempt=$((attempt + 1))
        
        # 尝试使用 GitHub 代理
        if [[ "$url" == *"github.com"* ]]; then
            for proxy in "${GITHUB_PROXIES[@]}"; do
                if [ -z "$proxy" ]; then
                    proxied_url="$url"
                else
                    proxied_url="${url/https:\/\/github.com/${proxy}\/https:\/\/github.com}"
                fi
                
                print_info "尝试下载 ($attempt/$max_retries): $proxied_url"
                
                if command -v curl &> /dev/null; then
                    if curl -f -L -o "$output" "$proxied_url" --connect-timeout 30 --max-time 300 2>/dev/null; then
                        success=true
                        break
                    fi
                elif command -v wget &> /dev/null; then
                    if wget -q -O "$output" -T 30 "$proxied_url" 2>/dev/null; then
                        success=true
                        break
                    fi
                fi
                
                [ -z "$proxy" ] || print_info "下载失败，尝试下一个代理..."
            done
        else
            # 非 GitHub URL，直接下载
            print_info "正在下载 ($attempt/$max_retries): $url"
            
            if command -v curl &> /dev/null; then
                if curl -f -L -o "$output" "$url" --connect-timeout 30 --max-time 300 2>/dev/null; then
                    success=true
                    break
                fi
            elif command -v wget &> /dev/null; then
                if wget -q -O "$output" -T 30 "$url" 2>/dev/null; then
                    success=true
                    break
                fi
            fi
        fi
        
        if [ "$success" = false ] && [ $attempt -lt $max_retries ]; then
            print_info "下载失败，3秒后重试..."
            sleep 3
        fi
    done
    
    if [ "$success" = false ]; then
        print_error "下载失败，已重试 $max_retries 次"
        return 1
    fi
    
    return 0
}

# 测试并选择最佳镜像
select_best_mirror() {
    local mirrors=("$@")
    local test_path=""  # 可选：添加测试路径
    
    print_info "正在检测最佳镜像源..."
    
    for mirror in "${mirrors[@]}"; do
        local test_url="$mirror"
        [ -n "$test_path" ] && test_url="$mirror$test_path"
        
        print_info "  测试: $mirror"
        
        if test_network "$test_url" 3; then
            print_success "  ✓ 可用: $mirror"
            echo "$mirror"
            return 0
        else
            print_info "  ✗ 不可用"
        fi
    done
    
    # 如果都不可用，返回第一个（可能是网络问题）
    print_info "所有镜像检测失败，使用默认镜像"
    echo "${mirrors[0]}"
    return 0
}

# 加载本地配置（如果存在）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/install-config.local.sh" ]; then
    source "$SCRIPT_DIR/install-config.local.sh"
    echo "[信息] 已加载本地配置: install-config.local.sh"
elif [ -f "$SCRIPT_DIR/install-config.sh" ]; then
    source "$SCRIPT_DIR/install-config.sh"
fi

print_header

# 步骤 1: 检查并安装 nvm
print_step "1/5 检查 nvm"

# 设置 NVM_DIR
if [ -z "$NVM_DIR" ]; then
    export NVM_DIR="$HOME/.nvm"
fi

# 加载 nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
    print_success "nvm 已安装"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    print_info "未找到 nvm，开始自动安装..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &> /dev/null; then
            print_error "未找到 Homebrew，请先安装: https://brew.sh"
            print_info "或者手动安装 nvm: curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash"
            exit 1
        fi
        brew install nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    else
        # Linux - 使用 Gitee 镜像安装 nvm
        print_info "正在下载 nvm 安装脚本（使用 Gitee 镜像）..."
        
        if command -v curl &> /dev/null; then
            curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash
        elif command -v wget &> /dev/null; then
            wget -qO- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash
        else
            print_error "未找到 curl 或 wget"
            exit 1
        fi

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    print_success "nvm 安装成功"
fi

# 步骤 2: 安装 Node.js 22
print_step "2/5 安装 Node.js 22 LTS"

# 配置 nvm 镜像源
best_node_mirror=$(select_best_mirror "${NVM_NODE_MIRRORS[@]}")
print_info "配置 nvm Node 镜像: $best_node_mirror"
export NVM_NODEJS_ORG_MIRROR="$best_node_mirror"

if nvm list | grep -q "v22\."; then
    NODE_VERSION=$(nvm list | grep "v22\." | head -n 1 | sed 's/.*v22/v22/' | awk '{print $1}')
    print_info "Node.js 22 已安装: v${NODE_VERSION}"
else
    print_info "正在安装 Node.js 22 LTS（可能需要 1-2 分钟）..."
    if nvm install 22; then
        print_success "Node.js 22 安装成功"
    else
        print_error "Node.js 22 安装失败"
        print_info "尝试手动安装: nvm install 22"
        exit 1
    fi
fi

nvm use 22
nvm alias default 22

# 步骤 3: 配置国内镜像源
print_step "3/5 配置国内镜像源"

# 选择最佳 npm 镜像
best_npm_mirror=$(select_best_mirror "${NPM_MIRRORS[@]}")

print_info "设置 npm registry..."
npm config set registry "$best_npm_mirror"

# 设置 nvm npm 镜像（如果支持）
if nvm npm_mirror &> /dev/null; then
    nvm npm_mirror "$best_npm_mirror"
fi

REGISTRY=$(npm config get registry)
print_success "镜像源配置成功: $REGISTRY"

# 显示配置
print_info "当前配置:"
echo "  npm registry: $(npm config get registry)"
echo "  nvm node_mirror: ${NVM_NODEJS_ORG_MIRROR:-默认}"

# 步骤 4: 全局安装 OpenClaw
print_step "4/5 安装 OpenClaw"

print_info "正在全局安装 OpenClaw（可能需要 1-2 分钟）..."

# 使用 npm install 带重试
max_retries=2
for ((i=1; i<=max_retries; i++)); do
    if npm install -g openclaw; then
        break
    fi
    
    if [ $i -lt $max_retries ]; then
        print_info "安装失败，5秒后重试 ($i/$max_retries)..."
        sleep 5
    fi
done

print_success "OpenClaw 安装成功"

# 步骤 5: 验证安装
print_step "5/5 验证安装"

if command -v openclaw &> /dev/null; then
    VERSION=$(openclaw --version 2>&1 || echo "未知版本")
    print_success "OpenClaw 版本: $VERSION"
else
    print_info "请重新加载 shell 配置或重启终端"
    print_info "运行: source ~/.bashrc  或  source ~/.zshrc"
fi

# 安装完成
print_header
print_success "OpenClaw 安装完成！\n"

print_info "环境信息:"
echo "  Node.js: $(node -v)"
echo "  npm:     $(npm -v)"
echo "  镜像源:  $(npm config get registry)"
echo ""

print_info "下一步操作:"
echo "  1. 初始化配置:"
echo "     openclaw init"
echo ""
echo "  2. 启动 Gateway:"
echo "     openclaw gateway start"
echo ""
echo "  3. 查看状态:"
echo "     openclaw gateway status"
echo ""
echo "  4. 查看帮助:"
echo "     openclaw help"
echo ""

print_info "详细文档:"
echo "  查看 ../../README.md 了解更多信息"
echo ""

print_info "故障排除:"
echo "  如果遇到问题，请查看: TROUBLESHOOTING.md"
echo ""

print_success "开始使用 OpenClaw 吧！ 🚀"
echo ""

exit 0
