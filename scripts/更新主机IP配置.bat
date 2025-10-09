@echo off
chcp 65001 >nul
title 更新主机IP配置
echo ================================================================================
echo MatMatch 项目 - 主机IP配置更新工具
echo ================================================================================
echo.

cd /d "%~dp0\.."

echo 当前需要更新的IP地址配置:
echo.
echo 📍 新主机IP: 172.16.100.211
echo.
echo 将更新以下文件:
echo   1. backend\core\config.py         - CORS origins
echo   2. backend\api\middleware.py      - Allowed origins  
echo   3. docs\项目配置-当前环境.md       - 文档更新
echo.
set /p CONFIRM="确认要更新配置？(Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo 已取消操作
    pause
    exit /b 0
)

echo.
echo 🔧 开始更新配置文件...
echo.

REM ======== 更新 backend/core/config.py ========
echo [1/3] 更新 backend\core\config.py...

REM 创建临时Python脚本来修改配置
echo import re > update_config.py
echo. >> update_config.py
echo file_path = "backend/core/config.py" >> update_config.py
echo with open(file_path, "r", encoding="utf-8") as f: >> update_config.py
echo     content = f.read() >> update_config.py
echo. >> update_config.py
echo # 在 cors_origins 中添加新IP >> update_config.py
echo pattern = r'(cors_origins:\s*list\s*=\s*Field\(\s*default=\[)([^\]]+)(\]' >> update_config.py
echo replacement = r'\1\2, "http://172.16.100.211:3000"\3' >> update_config.py
echo content = re.sub(pattern, replacement, content) >> update_config.py
echo. >> update_config.py
echo with open(file_path, "w", encoding="utf-8") as f: >> update_config.py
echo     f.write(content) >> update_config.py
echo. >> update_config.py
echo print("✅ backend/core/config.py 已更新") >> update_config.py

.\venv\Scripts\python.exe update_config.py
if %errorlevel% equ 0 (
    echo    ✅ 完成
) else (
    echo    ⚠️  更新失败，请手动修改
)

REM ======== 更新 backend/api/middleware.py ========
echo [2/3] 更新 backend\api\middleware.py...

echo import re > update_middleware.py
echo. >> update_middleware.py
echo file_path = "backend/api/middleware.py" >> update_middleware.py
echo with open(file_path, "r", encoding="utf-8") as f: >> update_middleware.py
echo     content = f.read() >> update_middleware.py
echo. >> update_middleware.py
echo # 在 allowed_origins 列表中添加新IP >> update_middleware.py
echo pattern = r'(allowed_origins\s*=\s*\[)([^\]]+)(\])' >> update_middleware.py
echo if '"http://172.16.100.211:3000"' not in content: >> update_middleware.py
echo     replacement = r'\1\2,\n            "http://172.16.100.211:3000",\n            "http://172.16.100.211:8080"\3' >> update_middleware.py
echo     content = re.sub(pattern, replacement, content) >> update_middleware.py
echo. >> update_middleware.py
echo with open(file_path, "w", encoding="utf-8") as f: >> update_middleware.py
echo     f.write(content) >> update_middleware.py
echo. >> update_middleware.py
echo print("✅ backend/api/middleware.py 已更新") >> update_middleware.py

.\venv\Scripts\python.exe update_middleware.py
if %errorlevel% equ 0 (
    echo    ✅ 完成
) else (
    echo    ⚠️  更新失败，请手动修改
)

REM ======== 更新文档 ========
echo [3/3] 更新 docs\项目配置-当前环境.md...

echo with open("docs/项目配置-当前环境.md", "r", encoding="utf-8") as f: > update_docs.py
echo     content = f.read() >> update_docs.py
echo. >> update_docs.py
echo # 在文档开头添加主机IP信息 >> update_docs.py
echo if "主机IP" not in content: >> update_docs.py
echo     content = content.replace( >> update_docs.py
echo         "**项目路径**: `D:\\develop\\python\\MatMatch`", >> update_docs.py
echo         "**项目路径**: `D:\\develop\\python\\MatMatch`\n**主机IP**: `172.16.100.211`" >> update_docs.py
echo     ) >> update_docs.py
echo. >> update_docs.py
echo with open("docs/项目配置-当前环境.md", "w", encoding="utf-8") as f: >> update_docs.py
echo     f.write(content) >> update_docs.py
echo. >> update_docs.py
echo print("✅ docs/项目配置-当前环境.md 已更新") >> update_docs.py

.\venv\Scripts\python.exe update_docs.py
if %errorlevel% equ 0 (
    echo    ✅ 完成
) else (
    echo    ⚠️  更新失败，请手动修改
)

REM 清理临时文件
del update_config.py update_middleware.py update_docs.py >nul 2>&1

echo.
echo ================================================================================
echo ✅ 配置更新完成！
echo.
echo 📋 已更新的配置:
echo   ✅ CORS允许来源: http://172.16.100.211:3000
echo   ✅ 中间件允许来源: http://172.16.100.211:3000/8080
echo   ✅ 文档主机IP: 172.16.100.211
echo.
echo 💡 提示:
echo   1. 如需允许局域网访问，启动后端时使用:
echo      python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
echo.
echo   2. 访问地址:
echo      - API文档: http://172.16.100.211:8000/docs
echo      - 前端界面: http://172.16.100.211:3000
echo.
echo   3. 其他机器访问前，请配置防火墙规则（参考迁移指南）
echo.
echo ================================================================================
pause

