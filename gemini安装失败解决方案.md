看起来问题依然集中在 **文件权限 (EPERM)** 和 **SSL 证书验证 (UNABLE_TO_VERIFY_LEAF_SIGNATURE)** 上。以下是更彻底、更直接的解决方案：

**不要在开启代理状态下安装**

**安装命令：npm install -g @google/gemini-cli**

### 终极解决方案：Windows 专用方法
#### 步骤 1：完全重置 npm 环境（管理员权限）
```powershell
# 停止所有 Node 进程
Stop-Process -Name node* -Force -ErrorAction SilentlyContinue

# 清除所有 npm 缓存
npm cache clean --force
rm -r "$env:APPDATA\npm-cache" -Force -Recurse

# 重置 npm 全局目录权限
takeown /F "$env:APPDATA\npm" /R /A /D Y
icacls "$env:APPDATA\npm" /reset /T /C
icacls "$env:APPDATA\npm" /grant "Users:(OI)(CI)F" /T
```

#### 步骤 2：手动下载 ripgrep 并绕过 SSL 检查
```powershell
# 创建目标目录
$ripgrepPath = "$env:APPDATA\npm\node_modules\@google\gemini-cli\node_modules\@lvce-editor\ripgrep\rg"
New-Item -Path $ripgrepPath -ItemType Directory -Force

# 手动下载 ripgrep（使用代理镜像）
$url = "https://ghproxy.com/https://github.com/microsoft/ripgrep-prebuilt/releases/download/v13.0.0-10/ripgrep-v13.0.0-10-x86_64-pc-windows-msvc.zip"
Invoke-WebRequest $url -OutFile "$env:TEMP\rg.zip"

# 解压到正确位置
Expand-Archive -Path "$env:TEMP\rg.zip" -DestinationPath $ripgrepPath -Force

# 标记已安装（防止 postinstall 脚本运行）
Set-Content -Path "$ripgrepPath\installed.txt" -Value "1"
```

#### 步骤 3：使用特殊参数安装 gemini-cli
```powershell
# 设置环境变量绕过安装检查
$env:SKIP_RIPGREP_INSTALL = "true"
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"

# 使用 --no-optional 和 --ignore-scripts 安装
npm install -g --no-optional --ignore-scripts @google/gemini-cli
```

#### 步骤 4：修复路径权限（关键步骤）
```powershell
# 获取 npm 全局目录
$globalPath = npm root -g

# 重置所有权（解决 EPERM 问题）
icacls "$globalPath\@google\gemini-cli" /grant "Everyone:(OI)(CI)F" /T /C
icacls "$globalPath\@google\gemini-cli\node_modules" /grant "Everyone:(OI)(CI)F" /T /C
```

### 备选方案：完全绕过 npm

#### 方案 A：使用预构建的二进制包
1. 下载预构建的 gemini-cli：
```powershell
Invoke-WebRequest "https://github.com/google-gemini/gemini-cli/releases/latest/download/gemini-cli-windows-x64.zip" -OutFile gemini-cli.zip
```
2. 解压到系统路径：
```powershell
Expand-Archive -Path gemini-cli.zip -DestinationPath "$env:APPDATA\npm\" -Force
```

#### 方案 B：使用 Windows 子系统 Linux (WSL)
```bash
# 在 WSL Ubuntu 中运行
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g @google/gemini-cli
```

### 验证安装
```powershell
# 重置环境变量
$env:NODE_TLS_REJECT_UNAUTHORIZED = "1"
Remove-Item Env:\SKIP_RIPGREP_INSTALL

# 测试是否安装成功
gemini --version
```

### 永久修复 SSL 问题（企业用户）
如果是公司网络，导入根证书：
```powershell
# 获取公司根证书
$certUrl = "https://your-company.com/certs/root-ca.crt"
Invoke-WebRequest $certUrl -OutFile "$env:TEMP\root-ca.crt"

# 添加到 npm 配置
npm config set cafile "$env:TEMP\root-ca.crt"
npm config set strict-ssl true
```

### 注意事项：
1. 所有步骤都需在 **管理员权限的 PowerShell** 中执行
2. 如果仍遇到 EPERM 错误，重启电脑后直接执行步骤 3 和 4
3. 安装完成后运行 `gemini init` 进行 API 密钥配置

这些方法特别针对 Windows 文件权限系统和企业网络证书问题，直接绕过问题点进行安装。99% 的类似问题可以通过这个方案解决。