@echo off
REM ============================================
REM 自动化数据同步和知识库更新脚本
REM 用途：定时执行完整的ETL和知识库更新流程
REM ============================================

REM 设置项目路径
cd /d D:\develop\python\MatMatch

REM 激活虚拟环境并执行完整流程
call .\venv\Scripts\activate.bat
python run_complete_pipeline.py

REM 记录执行时间
echo.
echo ============================================
echo 执行完成时间: %date% %time%
echo ============================================

REM 保持窗口打开（如果手动运行，取消下一行注释）
REM pause

