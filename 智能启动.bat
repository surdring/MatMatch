@echo off
chcp 65001 >nul
title MatMatch 系统启动
echo ================================================================================
echo MatMatch 系统启动脚本 v2.0
echo ================================================================================
echo.

cd /d "%~dp0"

:CHECK_PORTS
echo 🔍 正在检查服务状态...
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
    echo ⚠️  后端服务已在运行 (端口8000, PID: %BACKEND_PID%)
) else (
    echo ✅ 后端端口8000空闲
)

if %FRONTEND_RUNNING%==1 (
    echo ⚠️  前端服务已在运行 (端口3000, PID: %FRONTEND_PID%)
) else (
    echo ✅ 前端端口3000空闲
)
echo.

REM 如果有服务运行，询问用户
if %BACKEND_RUNNING%==1 (
    goto :ASK_RESTART
)
if %FRONTEND_RUNNING%==1 (
    goto :ASK_RESTART
)

REM 如果都没运行，直接启动
goto :START_SERVICES

:ASK_RESTART
echo.
echo 📋 检测到服务已在运行，您想要：
echo    [1] 停止现有服务并重新启动
echo    [2] 直接打开浏览器访问（不重启）
echo    [3] 退出
echo.
set /p CHOICE="请选择 (1/2/3): "

if "%CHOICE%"=="1" goto :STOP_SERVICES
if "%CHOICE%"=="2" goto :OPEN_BROWSER
if "%CHOICE%"=="3" goto :EXIT
echo ❌ 无效的选择，请重新输入
goto :ASK_RESTART

:STOP_SERVICES
echo.
echo 🛑 正在停止现有服务...

if %BACKEND_RUNNING%==1 (
    echo    - 停止后端服务 (PID: %BACKEND_PID%)
    taskkill /PID %BACKEND_PID% /F >nul 2>&1
    if %errorlevel%==0 (
        echo      ✅ 后端服务已停止
    ) else (
        echo      ⚠️  无法停止后端服务，可能需要管理员权限
    )
)

if %FRONTEND_RUNNING%==1 (
    echo    - 停止前端服务 (PID: %FRONTEND_PID%)
    taskkill /PID %FRONTEND_PID% /F >nul 2>&1
    if %errorlevel%==0 (
        echo      ✅ 前端服务已停止
    ) else (
        echo      ⚠️  无法停止前端服务，可能需要管理员权限
    )
)

REM 等待端口释放
echo    - 等待端口释放...
timeout /t 2 /nobreak >nul

REM 重新检查端口
goto :CHECK_PORTS

:START_SERVICES
echo.
echo 🚀 开始启动服务...
echo ================================================================================
echo.

REM 检查PostgreSQL
echo 🔍 检查PostgreSQL服务...
netstat -ano | findstr :5432 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL未运行，请先启动PostgreSQL服务
    echo.
    echo 📝 启动方法：
    echo    1. 打开"服务"管理器（services.msc）
    echo    2. 找到 PostgreSQL 服务
    echo    3. 右键 - 启动
    echo.
    pause
    exit /b 1
)
echo ✅ PostgreSQL运行正常
echo.

REM 启动Python脚本
echo 🚀 正在启动前后端服务...
echo.
echo 📌 后端API: http://localhost:8000
echo 📌 API文档: http://localhost:8000/docs  
echo 📌 前端界面: http://localhost:3000
echo.
echo ⏳ 请稍候，服务启动中...
echo ================================================================================
echo.

start "MatMatch 启动引擎" venv\Scripts\python.exe start_all.py

REM 等待服务启动
timeout /t 8 /nobreak >nul

:OPEN_BROWSER
echo.
echo 🌐 正在打开浏览器...
start http://localhost:3000

echo.
echo ================================================================================
echo ✅ 启动完成！
echo.
echo 📋 服务地址:
echo    - 前端界面: http://localhost:3000
echo    - 后端API:  http://localhost:8000
echo    - API文档:  http://localhost:8000/docs
echo.
echo 💡 提示:
echo    - 后端和前端日志将在新窗口中显示
echo    - 关闭日志窗口即可停止对应服务
echo    - 如需重启，请再次运行本脚本
echo ================================================================================
echo.

goto :END

:EXIT
echo.
echo 👋 已取消启动，再见！
exit /b 0

:END
