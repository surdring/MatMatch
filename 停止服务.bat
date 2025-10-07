@echo off
chcp 65001 >nul
title MatMatch 停止服务
echo ================================================================================
echo MatMatch 服务停止脚本
echo ================================================================================
echo.

cd /d "%~dp0"

echo 🔍 正在检查运行中的服务...
echo.

REM 检查后端端口8000
set BACKEND_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTENING') do (
    set BACKEND_PID=%%a
    set BACKEND_RUNNING=1
    goto :BACKEND_CHECK_DONE
)
:BACKEND_CHECK_DONE

REM 检查前端端口3000
set FRONTEND_RUNNING=0
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    set FRONTEND_PID=%%a
    set FRONTEND_RUNNING=1
    goto :FRONTEND_CHECK_DONE
)
:FRONTEND_CHECK_DONE

REM 显示检查结果
if %BACKEND_RUNNING%==1 (
    echo 🔴 后端服务运行中 (端口8000, PID: %BACKEND_PID%)
) else (
    echo ⚫ 后端服务未运行
)

if %FRONTEND_RUNNING%==1 (
    echo 🔴 前端服务运行中 (端口3000, PID: %FRONTEND_PID%)
) else (
    echo ⚫ 前端服务未运行
)
echo.

REM 如果都没运行
if %BACKEND_RUNNING%==0 (
    if %FRONTEND_RUNNING%==0 (
        echo ℹ️  没有运行中的服务需要停止
        echo.
        pause
        exit /b 0
    )
)

REM 询问确认
echo ⚠️  确定要停止服务吗？
echo.
set /p CONFIRM="输入 Y 确认停止，其他键取消: "

if /i not "%CONFIRM%"=="Y" (
    echo.
    echo ❌ 已取消停止操作
    pause
    exit /b 0
)

echo.
echo 🛑 正在停止服务...
echo.

REM 停止后端
if %BACKEND_RUNNING%==1 (
    echo [1/2] 停止后端服务...
    taskkill /PID %BACKEND_PID% /F /T >nul 2>&1
    if %errorlevel%==0 (
        echo      ✅ 后端服务已停止 (PID: %BACKEND_PID%)
    ) else (
        echo      ⚠️  无法停止后端服务，可能需要管理员权限
    )
    echo.
)

REM 停止前端
if %FRONTEND_RUNNING%==1 (
    echo [2/2] 停止前端服务...
    taskkill /PID %FRONTEND_PID% /F /T >nul 2>&1
    if %errorlevel%==0 (
        echo      ✅ 前端服务已停止 (PID: %FRONTEND_PID%)
    ) else (
        echo      ⚠️  无法停止前端服务，可能需要管理员权限
    )
    echo.
)

REM 等待端口释放
echo ⏳ 等待端口释放...
timeout /t 2 /nobreak >nul

REM 验证端口已释放
netstat -ano | findstr :8000 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo ✅ 端口8000已释放
) else (
    echo ⚠️  端口8000仍被占用
)

netstat -ano | findstr :3000 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo ✅ 端口3000已释放
) else (
    echo ⚠️  端口3000仍被占用
)

echo.
echo ================================================================================
echo ✅ 服务停止完成！
echo.
echo 💡 提示: 您可以重新运行 智能启动.bat 来启动服务
echo ================================================================================
echo.

pause

