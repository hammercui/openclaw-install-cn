# ============================================
# OpenClaw 增强版一键安装脚本 (PowerShell)
# ============================================
#
# 功能：
# - 自动测试多个镜像源速度
# - 选择最快的镜像源
# - 永久配置（重启终端不丢失）
# - 支持开机启动
#
# ============================================

# 设置错误处理
$ErrorActionPreference = "Stop"

# ============================================
# 镜像源配置
# ============================================

$NPM_MIRRORS = @{
    "淘宝镜像" = "https://registry.npmmirror.com"
    "腾讯云镜像" = "https://mirrors.cloud.tencent.com/npm/"
    "华为云镜像" = "https://mirrors.huaweicloud.com/repository/npm/"
    "清华大学镜像" = "https://registry.npmmirror.com"  # 通过淘宝
}

$NODE_MIRRORS = @{
    "淘宝镜像" = "https://npmmirror.com/mirrors/node/"
    "腾讯云镜像" = "https://mirrors.cloud.tencent.com/nodejs-release/"
    "华为云镜像" = "https://mirrors.huaweicloud.com/nodejs/"
}

# ============================================
# 工具函数
# ============================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    Write-ColorOutput "`n============================================" "Cyan"
    Write-ColorOutput "  OpenClaw 增强版一键安装" "Cyan"
    Write-ColorOutput "============================================`n" "Cyan"
}

function Write-Success {
    Write-ColorOutput "[✓] $args" "Green"
}

function Write-Info {
    Write-ColorOutput "[i] $args" "Yellow"
}

function Write-Error {
    Write-ColorOutput "[✗] $args" "Red"
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Description)
    Write-ColorOutput "`n[$Step/$Total] $Description`n" "Cyan"
}

# ============================================
# 镜像速度测试函数
# ============================================

function Test-MirrorSpeed {
    param(
        [string]$Url,
        [string]$Name
    )
    
    try {
        # 提取域名
        $uri = [System.Uri]$Url
        $domain = $uri.Host
        
        # 使用 Test-Connection 测试延迟
        $ping = Test-Connection -ComputerName $domain -Count 1 -ErrorAction SilentlyContinue
        
        if ($ping) {
            $latency = [math]::Round($ping.ResponseTime, 2)
            Write-ColorOutput "  测试 $name - ${latency}ms" "Gray"
            return @{
                Name = $Name
                Url = $Url
                Latency = $latency
            }
        } else {
            Write-ColorOutput "  测试 $name - 超时" "Red"
            return @{
                Name = $Name
                Url = $Url
                Latency = 99999
            }
        }
    } catch {
        Write-ColorOutput "  测试 $name - 失败" "Red"
        return @{
            Name = $Name
            Url = $Url
            Latency = 99999
        }
    }
}

function Select-BestMirror {
    param(
        [hashtable]$Mirrors,
        [string]$Type
    )
    
    Write-Info "测试 $Type 镜像源速度..."
    Write-Host ""
    
    $results = @()
    
    foreach ($mirror in $Mirrors.GetEnumerator()) {
        $result = Test-MirrorSpeed -Url $mirror.Value -Name $mirror.Key
        $results += $result
        Start-Sleep -Milliseconds 200
    }
    
    # 选择延迟最低的
    $best = $results | Sort-Object -Property Latency | Select-Object -First 1
    
    Write-Host ""
    Write-Success "选择: $($best.Name) ($($best.Latency)ms)"
    Write-Host ""
    
    return $best
}

# ============================================
# 永久配置函数
# ============================================

function Set-PermanentNpmConfig {
    param(
        [string]$RegistryUrl
    )
    
    Write-Info "配置 npm 镜像源（永久生效）..."
    Write-Host ""
    
    # 1. 配置当前用户
    npm config set registry $RegistryUrl
    
    # 2. 创建全局 .npmrc
    $globalNpmrc = "$env:APPDATA\npm\etc\npmrc"
    $globalEtc = Split-Path $globalNpmrc -Parent
    
    if (-not (Test-Path $globalEtc)) {
        New-Item -ItemType Directory -Path $globalEtc -Force | Out-Null
    }
    
    "registry=$RegistryUrl" | Out-File -FilePath $globalNpmrc -Encoding utf8
    Write-Success "创建全局配置: $globalNpmrc"
    
    # 3. 创建用户目录 .npmrc
    $userNpmrc = "$env:USERPROFILE\.npmrc"
    "registry=$RegistryUrl" | Out-File -FilePath $userNpmrc -Encoding utf8
    Write-Success "创建用户配置: $userNpmrc"
    
    Write-Host ""
    Write-Info "镜像源已永久配置，重启终端不会丢失"
    Write-Host ""
}

function Set-PermanentEnvironmentVariables {
    param([string]$NodeMirror)
    
    Write-Info "配置环境变量（永久生效）..."
    Write-Host ""
    
    # 1. 添加到 PATH
    $npmPath = "$env:APPDATA\npm"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$npmPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$npmPath", "User")
        Write-Success "PATH 已更新（永久）"
    } else {
        Write-Info "PATH 已配置"
    }
    
    # 2. 设置 NODE_MIRROR
    [Environment]::SetEnvironmentVariable("NODE_MIRROR", $NodeMirror, "User")
    Write-Success "NODE_MIRROR 已设置（永久）"
    
    # 3. 立即生效于当前会话
    $env:PATH = "$env:PATH;$npmPath"
    $env:NODE_MIRROR = $NodeMirror
    
    Write-Host ""
}

# ============================================
# 开机启动配置
# ============================================

function Set-AutoStart {
    Write-Info "配置开机启动..."
    Write-Host ""
    
    $response = Read-Host "是否配置 OpenClaw Gateway 开机启动? (Y/N)"
    
    if ($response -eq "Y" -or $response -eq "y") {
        # 检查管理员权限
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            # 使用注册表配置开机启动（推荐）
            $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            $regName = "OpenClawGateway"
            $regValue = "openclaw gateway start"
            
            try {
                Set-ItemProperty -Path $regPath -Name $regName -Value $regValue -Force
                Write-Success "已添加到注册表启动项"
                Write-Info "位置: $regPath"
                Write-Host ""
                Write-Info "下次开机时将自动启动 OpenClaw Gateway"
                Write-Info "取消命令: Remove-ItemProperty -Path '$regPath' -Name '$regName'"
            } catch {
                Write-Error "注册表配置失败: $_"
                Write-Host ""
                
                # 备选方案：启动文件夹
                $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
                $shortcutFile = "$startupFolder\OpenClawGateway.bat"
                
                "@echo off" | Out-File -FilePath $shortcutFile -Encoding ascii
                "start /min openclaw gateway start" | Out-File -FilePath $shortcutFile -Append -Encoding ascii
                
                Write-Success "已添加到启动文件夹: $shortcutFile"
            }
        } else {
            Write-Error "需要管理员权限才能配置开机启动"
            Write-Host ""
            Write-Info "请以管理员身份重新运行此脚本，或手动配置："
            Write-Host ""
            Write-Host "  1. 注册表方式（推荐）:"
            Write-Host "     reg add `"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`" /v `"OpenClawGateway`" /t REG_SZ /d `"openclaw gateway start`" /f" -ForegroundColor Gray
            Write-Host ""
            Write-Host "  2. 启动文件夹方式:"
            Write-Host "     创建快捷方式到: $env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
}

# ============================================
# 主安装流程
# ============================================

function Install-OpenClaw {
    Write-Header
    
    $totalSteps = 7
    
    # ============================================
    # Step 1: 测试并选择最快的镜像源
    # ============================================
    Write-Step 1 $totalSteps "测试镜像源速度并选择最优"
    
    $bestNpmMirror = Select-BestMirror -Mirrors $NPM_MIRRORS -Type "npm"
    $bestNodeMirror = Select-BestMirror -Mirrors $NODE_MIRRORS -Type "Node.js"
    
    Write-Host "========================================" "Gray"
    Write-Host "选择的镜像源:" "Cyan"
    Write-Host "  npm: $($bestNpmMirror.Name)" "White"
    Write-Host "  Node.js: $($bestNodeMirror.Name)" "White"
    Write-Host "========================================" "Gray"
    Write-Host ""
    
    # ============================================
    # Step 2: 检查/安装 Node.js
    # ============================================
    Write-Step 2 $totalSteps "检查 Node.js"
    
    $nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
    
    if ($nodeInstalled) {
        $nodeVersion = node -v
        Write-Success "Node.js 已安装: $nodeVersion"
    } else {
        Write-Info "Node.js 未安装，开始安装..."
        
        # 检查 nvm
        $nvmInstalled = Get-Command nvm -ErrorAction SilentlyContinue
        
        if ($nvmInstalled) {
            Write-Info "发现 nvm，使用 nvm 安装 Node.js"
            nvm install 22
            nvm use 22
        } else {
            Write-Info "下载 Node.js 安装程序..."
            Write-Info "使用镜像: $($bestNodeMirror.Name)"
            
            $nodeUrl = "$($bestNodeMirror.Url)v22.11.0/node-v22.11.0-x64.msi"
            $tempFile = "$env:TEMP\node-installer.msi"
            
            try {
                Invoke-WebRequest -Uri $nodeUrl -OutFile $tempFile -UseBasicParsing
                
                Write-Info "安装 Node.js..."
                $msiArgs = @(
                    "/i"
                    $tempFile
                    "/quiet"
                    "/norestart"
                )
                Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait
                
                Write-Success "Node.js 安装完成"
                
                # 刷新环境变量
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                
                Start-Sleep -Seconds 5
            } catch {
                Write-Error "Node.js 安装失败: $_"
                Write-Host ""
                Write-Host "请手动下载安装: $nodeUrl" -ForegroundColor Yellow
                exit 1
            } finally {
                if (Test-Path $tempFile) {
                    Remove-Item $tempFile -Force
                }
            }
        }
    }
    
    Write-Host ""
    
    # ============================================
    # Step 3: 配置 npm 镜像源（永久）
    # ============================================
    Write-Step 3 $totalSteps "配置 npm 镜像源"
    Set-PermanentNpmConfig -RegistryUrl $bestNpmMirror.Url
    
    # ============================================
    # Step 4: 配置环境变量（永久）
    # ============================================
    Write-Step 4 $totalSteps "配置环境变量"
    Set-PermanentEnvironmentVariables -NodeMirror $bestNodeMirror.Url
    
    # ============================================
    # Step 5: 安装 OpenClaw
    # ============================================
    Write-Step 5 $totalSteps "安装 OpenClaw"
    
    $openclawInstalled = npm list -g openclaw 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "OpenClaw 已安装，尝试更新..."
        npm update -g openclaw
    } else {
        Write-Info "正在安装 OpenClaw..."
        Write-Info "使用镜像: $($bestNpmMirror.Name)"
        npm install -g openclaw
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "OpenClaw 安装完成"
    } else {
        Write-Error "OpenClaw 安装失败"
        Write-Host ""
        Write-Host "可能的原因:" -ForegroundColor Yellow
        Write-Host "  1. 网络连接问题" -ForegroundColor Gray
        Write-Host "  2. 镜像源访问失败" -ForegroundColor Gray
        Write-Host "  3. 权限不足" -ForegroundColor Gray
        Write-Host ""
        Write-Host "建议:" -ForegroundColor Yellow
        Write-Host "  1. 检查网络连接" -ForegroundColor Gray
        Write-Host "  2. 尝试使用管理员权限运行" -ForegroundColor Gray
        Write-Host "  3. 查看镜像源延迟: $($bestNpmMirror.Latency)ms" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host ""
    
    # ============================================
    # Step 6: 验证安装
    # ============================================
    Write-Step 6 $totalSteps "验证安装"
    
    # 刷新 PATH
    $env:PATH = "$env:PATH;$env:APPDATA\npm"
    
    $openclawCmd = Get-Command openclaw -ErrorAction SilentlyContinue
    
    if ($openclawCmd) {
        $openclawVersion = openclaw --version 2>$null
        if ($openclawVersion) {
            Write-Success "OpenClaw 版本: $openclawVersion"
        }
    } else {
        Write-Error "openclaw 命令未找到"
        Write-Info "请手动添加到 PATH: %APPDATA%\npm"
        exit 1
    }
    
    Write-Host ""
    
    # ============================================
    # Step 7: 配置开机启动
    # ============================================
    Write-Step 7 $totalSteps "配置开机启动"
    Set-AutoStart
    
    # ============================================
    # 完成
    # ============================================
    Write-Host "========================================" "Cyan"
    Write-Success "安装完成！"
    Write-Host "========================================" "Cyan"
    Write-Host ""
    Write-Host "安装信息:" "White"
    Write-Host "  - OpenClaw 版本: $openclawVersion" "Gray"
    Write-Host "  - npm 镜像: $($bestNpmMirror.Name) ($($bestNpmMirror.Latency)ms)" "Gray"
    Write-Host "  - Node.js 镜像: $($bestNodeMirror.Name) ($($bestNodeMirror.Latency)ms)" "Gray"
    Write-Host "  - 永久配置: 是（重启终端不丢失）" "Gray"
    Write-Host ""
    Write-Host "下一步操作:" "White"
    Write-Host "  1. 初始化配置:" "Gray"
    Write-Host "     openclaw init" "White"
    Write-Host ""
    Write-Host "  2. 启动 Gateway:" "Gray"
    Write-Host "     openclaw gateway start" "White"
    Write-Host ""
    Write-Host "  3. 查看状态:" "Gray"
    Write-Host "     openclaw gateway status" "White"
    Write-Host ""
    Write-Host "文档位置:" "White"
    Write-Host "  - 快速开始: ..\QUICKSTART.md" "Gray"
    Write-Host "  - 完整文档: ..\README.md" "Gray"
    Write-Host "  - 故障排除: TROUBLESHOOTING.md" "Gray"
    Write-Host "========================================" "Cyan"
    Write-Host ""
    
    # 询问是否立即初始化
    $init = Read-Host "是否立即初始化 OpenClaw? (Y/N)"
    
    if ($init -eq "Y" -or $init -eq "y") {
        Write-Host ""
        Write-Info "正在初始化 OpenClaw..."
        openclaw init
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "初始化完成！"
            Write-Host ""
            
            $startGateway = Read-Host "是否立即启动 Gateway? (Y/N)"
            
            if ($startGateway -eq "Y" -or $startGateway -eq "y") {
                Write-Host ""
                Write-Info "正在启动 OpenClaw Gateway..."
                Start-Process -FilePath "openclaw" -ArgumentList "gateway", "start" -WindowStyle Minimized
                Write-Success "Gateway 已在后台启动"
                Write-Info "查看状态: openclaw gateway status"
            }
        } else {
            Write-Error "初始化失败，可以稍后手动运行: openclaw init"
        }
    }
    
    Write-Host ""
    Write-Host "========================================" "Cyan"
    Write-Host "配置文件位置:" "White"
    Write-Host "  - npm 配置: $env:USERPROFILE\.npmrc" "Gray"
    Write-Host "  - 全局配置: $env:APPDATA\npm\etc\npmrc" "Gray"
    Write-Host "  - 环境变量: 已永久设置（使用 [Environment]::SetEnvironmentVariable）" "Gray"
    Write-Host ""
    Write-Host "感谢使用 OpenClaw！" "Green"
    Write-Host "========================================" "Cyan"
    Write-Host ""
}

# ============================================
# 执行安装
# ============================================

try {
    Install-OpenClaw
} catch {
    Write-Error "安装失败: $_"
    Write-Host ""
    Write-Host "详细错误信息:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
