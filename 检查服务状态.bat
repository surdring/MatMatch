@echo off
chcp 65001 >nul
echo ================================================================================
echo MatMatch 服务状态检查
echo 检查时间: %date% %time%
echo ================================================================================
echo.

echo 🔍 检查后端API (端口8000)...
netstat -ano | findstr :8000 >nul
if %errorlevel% equ 0 (
    echo ✅ 后端服务运行中
    echo    访问地址: http://localhost:8000
    echo    API文档: http://localhost:8000/docs
) else (
    echo ❌ 后端服务未运行
)
echo.

echo 🔍 检查前端界面 (端口3000)...
netstat -ano | findstr :3000 >nul
if %errorlevel% equ 0 (
    echo ✅ 前端服务运行中
    echo    访问地址: http://localhost:3000
) else (
    echo ❌ 前端服务未运行
)
echo.

echo 🔍 检查PostgreSQL (端口5432)...
netstat -ano | findstr :5432 >nul
if %errorlevel% equ 0 (
    echo ✅ PostgreSQL运行中
) else (
    echo ❌ PostgreSQL未运行
    echo    请启动PostgreSQL服务
)
echo.

echo 🔍 检查知识库状态...
venv\Scripts\python.exe -c "import asyncio; from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession; from sqlalchemy.orm import sessionmaker; from sqlalchemy import text; import sys; sys.path.insert(0, 'backend'); from backend.core.config import database_config; async def check(): engine = create_async_engine(database_config.database_url); async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False); async with async_session() as session: r1 = await session.execute(text('SELECT COUNT(*) FROM extraction_rules')); r2 = await session.execute(text('SELECT COUNT(*) FROM synonyms')); r3 = await session.execute(text('SELECT COUNT(*) FROM knowledge_categories')); r4 = await session.execute(text('SELECT COUNT(*) FROM materials_master')); print(f'  - 提取规则: {r1.scalar()} 条'); print(f'  - 同义词: {r2.scalar()} 条'); print(f'  - 分类: {r3.scalar()} 个'); print(f'  - 物料数据: {r4.scalar()} 条'); await engine.dispose(); asyncio.run(check())" 2>nul
if %errorlevel% neq 0 (
    echo ❌ 无法连接数据库或知识库未初始化
)
echo.

echo ================================================================================
echo 💡 提示:
echo   - 如需启动服务,请运行: 智能启动.bat
echo   - 如需数据同步,请运行: 定时数据同步.bat
echo ================================================================================
echo.

pause


