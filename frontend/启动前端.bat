@echo off
chcp 65001 >nul
cd /d %~dp0
title MatMatch 前端开发服务器
echo ================================================================================
echo MatMatch 前端开发服务器启动
echo ================================================================================
echo.

REM 检查 node_modules 是否存在
if not exist "node_modules\" (
    echo ⚠️  检测到 node_modules 不存在，正在安装依赖...
    echo.
    call npm install
    echo.
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败，请检查 npm 配置
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
    echo.
)

REM 检查端口 3000 是否被占用
echo 🔍 正在检查端口 3000...
netstat -ano | findstr :3000 | findstr LISTENING >nul
if %errorlevel% equ 0 (
    echo ⚠️  端口 3000 已被占用
    echo.
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
        set PID=%%a
        goto :PID_FOUND
    )
    :PID_FOUND
    echo 当前占用进程 PID: %PID%
    echo.
    set /p KILL_PROCESS="是否要停止该进程并重启前端服务？(Y/N): "
    if /i "%KILL_PROCESS%"=="Y" (
        echo 正在停止进程 %PID%...
        taskkill /PID %PID% /F >nul 2>&1
        if %errorlevel% equ 0 (
            echo ✅ 进程已停止
            timeout /t 2 /nobreak >nul
        ) else (
            echo ❌ 停止进程失败，可能需要管理员权限
            pause
            exit /b 1
        )
    ) else (
        echo 已取消启动
        pause
        exit /b 0
    )
)
echo ✅ 端口 3000 空闲
echo.

echo 🚀 正在启动前端开发服务器...
echo.
echo 📦 服务地址: http://localhost:3000
echo 📦 网络地址: http://192.168.x.x:3000
echo.
echo 💡 提示:
echo    - 按 Ctrl+C 停止服务器
echo    - 代码更改会自动热更新
echo    - 关闭此窗口将停止前端服务
echo.
echo ================================================================================
echo.

REM 启动 Vite 开发服务器
call npm run dev

pause

