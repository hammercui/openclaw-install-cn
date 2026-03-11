# ============================================
# OpenClaw 安装配置文件 (PowerShell)
# ============================================
# 说明：复制此文件为 install-config.local.ps1 并自定义配置
# 安装脚本会自动加载 install-config.local.ps1（如果存在）

# ============================================
# npm 镜像源配置
# ============================================
# 优先级从高到低，安装脚本会自动选择可用的镜像
$NpmMirrors = @(
    "https://registry.npmmirror.com",          # 淘宝镜像（推荐）
    "https://mirrors.cloud.tencent.com/npm",   # 腾讯云镜像
    "https://mirrors.huaweicloud.com/repository/npm/",  # 华为云镜像
    "https://registry.npmjs.org"               # npm 官方源
)

# ============================================
# Node.js 镜像源配置
# ============================================
# 用于 nvm 下载 Node.js
$NvmNodeMirrors = @(
    "https://npmmirror.com/mirrors/node",      # 淘宝 Node 镜像（推荐）
    "https://mirrors.cloud.tencent.com/npm/",  # 腾讯云 Node 镜像
    "https://nodejs.org/dist"                  # Node.js 官方源
)

# ============================================
# GitHub 代理配置（解决国内访问慢）
# ============================================
# 用于下载 GitHub 上的资源
$GithubProxies = @(
    "https://mirror.ghproxy.com",              # GHProxy 镜像
    "https://ghproxy.net",                     # GHProxy 备用
    "https://ghps.cc",                         # GHProxy 另一个镜像
    ""                                          # 直连（留空表示不使用代理）
)

# ============================================
# Node.js 版本配置
# ============================================
# 默认安装的 Node.js 版本
$NodeVersion = "22"

# ============================================
# 网络检测配置
# ============================================
# 镜像检测超时时间（毫秒）
$MirrorTestTimeout = 3000

# 下载重试次数
$DownloadMaxRetries = 3

# ============================================
# 安装选项
# ============================================
# 是否跳过网络检测（如果网络检测不准确，可以设置为 $true）
$SkipNetworkCheck = $false

# 是否在安装完成后自动初始化 OpenClaw
$AutoInit = $false

# 是否在安装完成后自动启动 Gateway
$AutoStartGateway = $false

# ============================================
# 日志配置
# ============================================
# 安装日志路径（留空则不记录日志）
$InstallLogPath = ""

# ============================================
# 代理配置（可选）
# ============================================
# 如果需要使用 HTTP/HTTPS 代理
# $env:HTTP_PROXY = "http://127.0.0.1:7890"
# $env:HTTPS_PROXY = "http://127.0.0.1:7890"

# ============================================
# 使用说明
# ============================================
# 1. 复制此文件：
#    cp install-config.example.ps1 install-config.local.ps1
#
# 2. 编辑 install-config.local.ps1，修改配置
#
# 3. 运行安装脚本（会自动加载配置）：
#    .\install.bat
#
# 注意：install-config.local.ps1 会被 .gitignore 忽略，
#       所以你的自定义配置不会被提交到 git 仓库
