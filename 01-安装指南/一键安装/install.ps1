# ============================================
# OpenClaw 一键安装脚本 (Windows PowerShell)
# 优化版：国内网络加速 + 错误重试
# ============================================

# 设置错误处理
$ErrorActionPreference = "Stop"

# 国内镜像配置（优先级从高到低）
$NPM_MIRRORS = @(
    "https://registry.npmmirror.com",      # 淘宝镜像（主）
    "https://mirrors.cloud.tencent.com/npm", # 腾讯云镜像（备）
    "https://mirrors.huaweicloud.com/repository/npm/"  # 华为云镜像（备）
)

$NVM_NODE_MIRRORS = @(
    "https://npmmirror.com/mirrors/node",  # 淘宝 Node 镜像（主）
    "https://mirrors.cloud.tencent.com/npm/",  # 腾讯云 Node 镜像（备）
    "https://nodejs.org/dist"               # 官方源（最后）
)

# GitHub 下载代理（解决国内访问慢）
$GITHUB_PROXIES = @(
    "https://mirror.ghproxy.com",          # GHProxy 镜像（主）
    "https://ghproxy.net",                  # GHProxy 备用
    ""                                       # 直连（最后）
)

# 颜色输出函数
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header {
    Write-ColorOutput Cyan "`n============================================"
    Write-ColorOutput Cyan "    OpenClaw 一键安装 (国内优化版)"
    Write-ColorOutput Cyan "============================================`n"
}

function Write-Success {
    Write-ColorOutput Green "[成功] $args"
}

function Write-Info {
    Write-ColorOutput Yellow "[信息] $args"
}

function Write-Error {
    Write-ColorOutput Red "[错误] $args"
}

function Write-Step {
    Write-ColorOutput Cyan "`n[步骤] $args`n"
}

# 网络检测函数
function Test-Network {
    param(
        [string]$Url,
        [int]$TimeoutMs = 5000
    )
    try {
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.Timeout = $TimeoutMs
        $request.Method = "HEAD"
        $request.UserAgent = "OpenClaw-Installer/1.0"
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

# 下载函数（带重试和代理）
function Invoke-DownloadWithRetry {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 3
    )
    
    $attempts = 0
    $success = $false
    
    while (-not $success -and $attempts -lt $MaxRetries) {
        $attempts++
        
        try {
            # 尝试使用 GitHub 代理
            if ($Url -match "github\.com") {
                foreach ($proxy in $GITHUB_PROXIES) {
                    if ([string]::IsNullOrEmpty($proxy)) {
                        $proxiedUrl = $Url
                    } else {
                        $proxiedUrl = $Url -replace "https://github\.com", "$proxy/https://github.com"
                    }
                    
                    Write-Info "尝试下载 ($attempts/$MaxRetries): $proxiedUrl"
                    
                    try {
                        Invoke-WebRequest -Uri $proxiedUrl -OutFile $OutputPath -UseBasicParsing -TimeoutSec 30
                        $success = $true
                        break
                    } catch {
                        Write-Info "下载失败，尝试下一个代理..."
                        continue
                    }
                }
            } else {
                # 非 GitHub URL，直接下载
                Write-Info "正在下载 ($attempts/$MaxRetries): $Url"
                Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -TimeoutSec 30
                $success = $true
            }
        } catch {
            if ($attempts -lt $MaxRetries) {
                Write-Info "下载失败，3秒后重试..."
                Start-Sleep -Seconds 3
            }
        }
    }
    
    if (-not $success) {
        throw "下载失败，已重试 $MaxRetries 次"
    }
}

# 测试并选择最佳镜像
function Select-BestMirror {
    param(
        [string[]]$Mirrors,
        [string]$TestPath = ""
    )
    
    Write-Info "正在检测最佳镜像源..."
    
    foreach ($mirror in $Mirrors) {
        $testUrl = if ($TestPath) { "$mirror$TestPath" } else { $mirror }
        Write-Info "  测试: $mirror"
        
        if (Test-Network -Url $testUrl -TimeoutMs 3000) {
            Write-Success "  ✓ 可用: $mirror"
            return $mirror
        } else {
            Write-Info "  ✗ 不可用"
        }
    }
    
    # 如果都不可用，返回第一个（可能是网络问题）
    Write-Info "所有镜像检测失败，使用默认镜像"
    return $Mirrors[0]
}

# 加载本地配置（如果存在）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LocalConfig = Join-Path $ScriptDir "install-config.local.ps1"
$DefaultConfig = Join-Path $ScriptDir "install-config.example.ps1"

if (Test-Path $LocalConfig) {
    . $LocalConfig
    Write-Info "已加载本地配置: install-config.local.ps1"
} elseif (Test-Path $DefaultConfig) {
    . $DefaultConfig
}

Write-Header

# 步骤 1: 检查并安装 nvm-windows
Write-Step "1/5 检查 nvm-windows"

$NvmPath = "$env:APPDATA\nvm\nvm.exe"
if (-not (Test-Path $NvmPath)) {
    Write-Info "未找到 nvm-windows，开始自动安装..."

    # 选择最佳 Node 镜像
    $BestNodeMirror = Select-BestMirror -Mirrors $NVM_NODE_MIRRORS
    
    $NvmInstallerUrl = "https://github.com/coreybutler/nvm-windows/releases/download/1.1.12/nvm-setup.exe"
    $NvmInstaller = "$env:TEMP\nvm-setup.exe"

    try {
        Write-Info "正在下载 nvm-windows（使用国内加速）..."
        Invoke-DownloadWithRetry -Url $NvmInstallerUrl -OutputPath $NvmInstaller

        Write-Info "正在安装 nvm-windows..."
        Start-Process -FilePath $NvmInstaller -Wait

        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        Write-Success "nvm-windows 安装成功"
    } catch {
        Write-Error "nvm-windows 安装失败: $_"
        Write-Info "请手动安装: https://github.com/coreybutler/nvm-windows/releases"
        Write-Info "或使用国内镜像: https://gitee.com/mirrors/nvm-windows/releases"
        exit 1
    }
} else {
    Write-Success "nvm-windows 已安装"
}

# 步骤 2: 安装 Node.js 22
Write-Step "2/5 安装 Node.js 22 LTS"

# 刷新环境变量
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

try {
    # 配置 nvm 镜像源
    $BestNodeMirror = Select-BestMirror -Mirrors $NVM_NODE_MIRRORS
    Write-Info "配置 nvm Node 镜像: $BestNodeMirror"
    & nvm node_mirror $BestNodeMirror
    
    # 检查是否已安装 Node.js 22
    $NodeVersion = & nvm list 2>&1 | Select-String "22\." | Select-Object -First 1

    if ($NodeVersion) {
        Write-Info "Node.js 22 已安装: $($NodeVersion.ToString().Trim())"
    } else {
        Write-Info "正在安装 Node.js 22 LTS..."
        & nvm install 22
        
        if ($LASTEXITCODE -eq 0) {
            & nvm use 22
            Write-Success "Node.js 22 安装成功"
        } else {
            throw "nvm install 22 失败"
        }
    }

    & nvm use 22
} catch {
    Write-Error "Node.js 22 安装失败: $_"
    Write-Info "尝试手动安装: nvm install 22"
    exit 1
}

# 步骤 3: 配置国内镜像源
Write-Step "3/5 配置国内镜像源"

try {
    # 选择最佳 npm 镜像
    $BestNpmMirror = Select-BestMirror -Mirrors $NPM_MIRRORS
    
    Write-Info "设置 npm registry..."
    npm config set registry $BestNpmMirror

    Write-Info "设置 nvm npm 镜像..."
    & nvm npm_mirror $BestNpmMirror

    $Registry = npm config get registry
    Write-Success "镜像源配置成功: $Registry"
    
    # 显示配置
    Write-Info "当前配置:"
    Write-Output "  npm registry: $(npm config get registry)"
    Write-Output "  nvm node_mirror: $(nvm node_mirror)"
    Write-Output "  nvm npm_mirror: $(nvm npm_mirror)"
} catch {
    Write-Error "镜像源配置失败: $_"
    exit 1
}

# 步骤 4: 全局安装 OpenClaw
Write-Step "4/5 安装 OpenClaw"

try {
    Write-Info "正在全局安装 OpenClaw（可能需要 1-2 分钟）..."
    
    # 使用 npm install 带重试
    $maxRetries = 2
    for ($i = 1; $i -le $maxRetries; $i++) {
        npm install -g openclaw
        if ($LASTEXITCODE -eq 0) {
            break
        }
        
        if ($i -lt $maxRetries) {
            Write-Info "安装失败，5秒后重试 ($i/$maxRetries)..."
            Start-Sleep -Seconds 5
        }
    }

    Write-Success "OpenClaw 安装成功"
} catch {
    Write-Error "OpenClaw 安装失败: $_"
    Write-Info "尝试手动安装: npm install -g openclaw"
    exit 1
}

# 验证安装
Write-Step "5/5 验证安装"

try {
    $Version = openclaw --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "OpenClaw 版本: $Version"
    } else {
        Write-Info "无法获取版本信息（可能需要重启终端）"
    }
} catch {
    Write-Info "请重启终端后验证安装"
}

# 安装完成
Write-Header
Write-Success "OpenClaw 安装完成！`n"

Write-Info "环境信息:"
Write-Output "  Node.js: $(node -v)"
Write-Output "  npm:     $(npm -v)"
Write-Output "  镜像源:  $(npm config get registry)"
Write-Output ""

Write-Info "下一步操作:"
Write-Output "  1. 初始化配置:"
Write-Output "     openclaw init"
Write-Output ""
Write-Output "  2. 启动 Gateway:"
Write-Output "     openclaw gateway start"
Write-Output ""
Write-Output "  3. 查看状态:"
Write-Output "     openclaw gateway status"
Write-Output ""
Write-Output "  4. 查看帮助:"
Write-Output "     openclaw help"
Write-Output ""

Write-Info "详细文档:"
Write-Output "  查看 ..\..\README.md 了解更多信息"
Write-Output ""

Write-Info "故障排除:"
Write-Output "  如果遇到问题，请查看: TROUBLESHOOTING.md"
Write-Output ""

Write-Success "开始使用 OpenClaw 吧！ 🚀`n"

exit 0
