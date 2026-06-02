from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from model_service.model_loader import (
    load_sbert_model,
    load_recipe_embeddings,
    load_recipe_metadata,
)
from model_service.recommender import get_recommendations_for_labels_sbert
from model_service.qwen_classifier import classify_image as qwen_classify_image
import uvicorn
import os

app = FastAPI()

# Allow CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],
    allow_methods=['*'],
    allow_headers=['*'],
)

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Load SBERT model and embeddings once at startup for efficiency
SBERT = load_sbert_model()
EMBEDDINGS, EMBEDDING_RECIPE_IDS = load_recipe_embeddings()
RECIPE_METADATA = load_recipe_metadata()

@app.get("/recommendations/by_labels")
def get_recommendations_by_labels(labels: str, n: int = 5):
    cleaned = [label.strip() for label in labels.split(",") if label.strip()]
    if not cleaned:
        return {"recommendations": []}

    query_embedding = SBERT.encode(" ".join(cleaned))
    recommendations = get_recommendations_for_labels_sbert(
        query_embedding,
        EMBEDDINGS,
        EMBEDDING_RECIPE_IDS,
        RECIPE_METADATA,
        cleaned,
        n=n,
    )
    return {"recommendations": recommendations}

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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)