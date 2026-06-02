from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from backend.model_service.food_classifier import FoodClassifier
from backend.model_service.openrouter_classifier import classify_image as openrouter_classify_image
from pydantic import BaseModel
import logging
import os

app = FastAPI()

# Allow CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)

class WeightData(BaseModel):
    weight: float
    unit: str = 'g'

# Initialize HuggingFace classifier
from transformers import pipeline
classifier = FoodClassifier()

# Remove Gemini dependency - update FoodClassifier to use HuggingFace internally

@app.post('/classify')
async def classify_image(file: UploadFile = File(...)):
    try:
        # Save temp file
        temp_path = 'temp_image.jpg'
        with open(temp_path, 'wb') as buffer:
            buffer.write(await file.read())

        # Classify (now includes scrap augmentation)
        results = classifier.classify(temp_path)
        return {
            'predictions': results,
            'scrap_features': [r['label'] for r in results if '_peel' in r['label'].lower() or '_skin' in r['label'].lower()]
        }
    except Exception as e:
        logging.error(f'Classification error: {str(e)}')
        return {'error': str(e)}
    finally:
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)

@app.post('/weight')
async def receive_weight(data: WeightData):
    # Store weight data for correlation with images
    return {'status': 'received', 'weight': data.weight, 'unit': data.unit}

@app.post('/classify-food-scrap')
async def classify_food_scrap(image: UploadFile = File(...)):
    temp_dir = "temp"
    os.makedirs(temp_dir, exist_ok=True)
    image_path = os.path.join(temp_dir, image.filename)
    try:
        with open(image_path, "wb") as f:
            f.write(await image.read())
        result = openrouter_classify_image(image_path)
        return {"classification": result}
    finally:
        if os.path.exists(image_path):
            os.remove(image_path)
