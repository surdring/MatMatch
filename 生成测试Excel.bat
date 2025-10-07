@echo off
chcp 65001 >nul
echo ========================================
echo 生成物料查重测试Excel文件
echo ========================================
echo.

cd /d %~dp0

echo [1/2] 激活虚拟环境...
call venv\Scripts\activate.bat

echo.
echo [2/2] 生成测试数据...
python backend\scripts\generate_test_excel.py

echo.
echo ========================================
echo 完成！
echo ========================================
echo.
pause

