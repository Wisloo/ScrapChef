#!/bin/bash
# Startup script for Hugging Face Spaces

# Install dependencies
pip install -r requirements.txt

# Run the FastAPI server
uvicorn main:app --host 0.0.0.0 --port 7860
