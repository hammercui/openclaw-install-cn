# Windows 一键安装指南

## 快速开始

右键 `install-windows.bat` → **以管理员身份运行**（推荐）。

普通用户权限也可运行，Node.js 将安装到用户目录，无需 UAC。

---

## 安装过程说明

脚本分 4 个阶段，全程自动执行：

| 阶段 | 内容 |
|------|------|
| 1/4 | 测试镜像速度，选择最快的 npm / Node.js 镜像源 |
| 2/4 | 安装基础工具：Git 2.48、Node.js 22、pnpm |
| 3/4 | 安装 OpenClaw（pnpm 优先，npm 备用） |
| 4/4 | 验证安装，配置开机自启动（可选，询问） |

**镜像源**：自动从淘宝、腾讯云、华为云中选最快的。

**权限区别**：
- 管理员：Node.js 使用 MSI 安装，Git 使用系统级安装
- 普通用户：Node.js 解压到 `%LOCALAPPDATA%\Programs\nodejs`，无需 UAC

---

## 安装完成后

脚本最后会询问是否立即初始化并启动：

```cmd
openclaw init             # 初始化配置
openclaw gateway start    # 启动 Gateway
openclaw gateway status   # 查看状态
openclaw --help           # 查看所有命令
```

**取消开机自启动**：

```cmd
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OpenClawGateway" /f
```

---

## 故障排除

**`openclaw` 命令找不到**

```cmd
# 在当前会话临时添加路径
set PATH=%PATH%;%APPDATA%\npm
# 或重启命令提示符（setx 已永久写入 PATH，重启后自动生效）
```

**Node.js 安装失败**

```cmd
# 手动下载并安装 Node.js 22
msiexec /i node-v22.12.0-x64.msi
```

**npm install 失败**

```cmd
npm config set registry https://registry.npmmirror.com
npm cache clean --force
npm install -g openclaw
```

**查看完整日志**

```cmd
type %TEMP%\openclaw-install.log
```
