@echo off
echo Starting ngrok tunnels for venue presentation...
echo.
echo Flask Server (ESP32 data): https://YOUR-FLASK-URL.ngrok-free.app
echo FastAPI Backend (ML): https://YOUR-FASTAPI-URL.ngrok-free.app
echo.
echo Press Ctrl+C to stop ngrok
echo.

ngrok start flask-server fastapi-backend
