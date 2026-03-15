@echo off
echo ========================================
echo Starting Cognify AI Backend
echo ========================================

echo.
echo Installing requirements...
pip install -r requirements.txt

echo.
echo Starting FastAPI server...
python main.py

pause
