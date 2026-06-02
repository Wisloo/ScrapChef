# Venue Presentation Guide

## Setup Instructions

### 1. Install ngrok
```bash
# Download from https://ngrok.com/download
# Or use: choco install ngrok (if using Chocolatey)
```

### 2. Get Auth Token
- Sign up at https://ngrok.com/signup (free)
- Get your authtoken from dashboard
- Update `ngrok.yml` with your token

### 3. Start Your Local Servers
```bash
# Terminal 1: Flask server
python server.py

# Terminal 2: FastAPI backend  
python backend/main.py
```

### 4. Start ngrok
```bash
# Option A: Use config file
ngrok start flask-server fastapi-backend

# Option B: Run individually
ngrok http 3000
ngrok http 8000
```

### 5. Update Flutter App
At the venue, update your `.env`:
```
BACKEND_URL=https://YOUR-FASTAPI-URL.ngrok-free.app
```

## At the Venue

1. Connect to venue WiFi
2. Start your local servers
3. Start ngrok
4. Note the public URLs ngrok provides
5. Update Flutter app with ngrok URLs
6. Demo your app

## Important Notes

- ngrok free tier has some limitations but works for presentations
- URLs change each time you restart ngrok
- Keep your laptop running during presentation
- Test everything before going to venue
