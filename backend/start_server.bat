@echo off
cd /d %~dp0
echo Starting MatMatch API Server...
echo.
..\venv\Scripts\python.exe -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload
pause

