from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import pandas as pd
import numpy as np
from sentence_transformers import SentenceTransformer
import torch
import json
from sklearn.metrics.pairwise import cosine_similarity
import os

app = FastAPI(title="Recipe RAG API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for model and data
model = None
recipe_df = None
recipe_embeddings = None
scrap_mapping = None

# Paths
MODEL_PATH = os.path.join(os.path.dirname(__file__), "sbert_model")
RECIPE_EMBEDDINGS_PATH = os.path.join(MODEL_PATH, "df_recipes_with_embeddings.parquet")
SCRAP_MAPPING_PATH = os.path.join(MODEL_PATH, "scrap_mapping.json")


class RecommendationRequest(BaseModel):
    query: str
    top_k: int = 5
    use_scrap_mapping: bool = True


class ScrapRecommendationRequest(BaseModel):
    scraps: List[str]
    top_k: int = 5


class RecipeResponse(BaseModel):
    title: str
    ingredients: str
    instructions: Optional[str] = None
    similarity_score: float
    image_url: Optional[str] = None


def load_model_and_data():
    """Load the SBERT model, recipe embeddings, and scrap mapping."""
    global model, recipe_df, recipe_embeddings, scrap_mapping
    
    try:
        # Load SBERT model
        print("Loading SBERT model...")
        model = SentenceTransformer(MODEL_PATH)
        
        # Load recipe embeddings
        print("Loading recipe embeddings...")
        recipe_df = pd.read_parquet(RECIPE_EMBEDDINGS_PATH)
        
        # Extract embeddings column
        if 'embeddings' in recipe_df.columns:
            recipe_embeddings = np.array(recipe_df['embeddings'].tolist())
        elif 'embedding' in recipe_df.columns:
            recipe_embeddings = np.array(recipe_df['embedding'].tolist())
        else:
            # Try to find the embedding column
            embedding_cols = [col for col in recipe_df.columns if 'embed' in col.lower()]
            if embedding_cols:
                recipe_embeddings = np.array(recipe_df[embedding_cols[0]].tolist())
            else:
                raise ValueError("No embedding column found in recipe data")
        
        # Load scrap mapping
        print("Loading scrap mapping...")
        with open(SCRAP_MAPPING_PATH, 'r') as f:
            scrap_mapping = json.load(f)
        
        print("Model and data loaded successfully!")
        
    except Exception as e:
        print(f"Error loading model and data: {e}")
        raise


@app.on_event("startup")
async def startup_event():
    """Load model and data on startup."""
    load_model_and_data()


def map_scraps_to_ingredients(scraps: List[str]) -> List[str]:
    """Map scrap items to their corresponding ingredients."""
    ingredients = []
    for scrap in scraps:
        scrap_lower = scrap.lower().strip()
        if scrap_lower in scrap_mapping:
            ingredients.append(scrap_mapping[scrap_lower])
        else:
            # If no exact match, try partial match
            for key, value in scrap_mapping.items():
                if scrap_lower in key or key in scrap_lower:
                    ingredients.append(value)
                    break
            else:
                # If no match found, keep the original
                ingredients.append(scrap)
    return ingredients


def get_recipe_recommendations(query: str, top_k: int = 5) -> List[RecipeResponse]:
    """Get recipe recommendations based on query using semantic search."""
    global model, recipe_df, recipe_embeddings
    
    if model is None or recipe_df is None or recipe_embeddings is None:
        raise HTTPException(status_code=500, detail="Model or data not loaded")
    
    # Encode the query
    query_embedding = model.encode([query])
    
    # Calculate cosine similarity
    similarities = cosine_similarity(query_embedding, recipe_embeddings)[0]
    
    # Get top-k indices
    top_indices = np.argsort(similarities)[::-1][:top_k]
    
    # Prepare response
    recommendations = []
    for idx in top_indices:
        recipe = recipe_df.iloc[idx]
        
        # Extract recipe information using correct column names
        title = recipe.get('Name', recipe.get('title', recipe.get('name', 'Unknown')))
        ingredients = recipe.get('RecipeIngredientParts', recipe.get('ingredients', recipe.get('ingredient_lines', '')))
        instructions = recipe.get('RecipeInstructions', recipe.get('instructions', recipe.get('steps', None)))
        images = recipe.get('Images', None)
        
        # Convert ingredients to string if it's a list
        if isinstance(ingredients, list):
            ingredients = ', '.join(map(str, ingredients))
        
        # Convert instructions to string if it's a list
        if isinstance(instructions, list):
            instructions = ' '.join(map(str, instructions))
        
        # Get first image URL if available
        first_image_url = None
        if images and pd.notna(images):
            if isinstance(images, str):
                # Split by ", " (comma followed by space) to separate multiple URLs
                # URLs contain commas in their parameters, so we need to be careful
                image_urls = [url.strip() for url in images.split(', ') if url.strip()]
                if len(image_urls) > 0:
                    first_image_url = image_urls[0]
                    # Ensure URL is complete and valid (at least 50 chars for full URL)
                    if first_image_url and len(first_image_url) > 50 and first_image_url.startswith('http'):
                        pass  # Valid URL
                    else:
                        first_image_url = None
        
        recommendations.append(RecipeResponse(
            title=title,
            ingredients=ingredients,
            instructions=instructions,
            similarity_score=float(similarities[idx]),
            image_url=first_image_url
        ))
    
    return recommendations


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Recipe RAG API",
        "endpoints": {
            "/recommend": "POST - Get recipe recommendations based on query",
            "/recommend-from-scraps": "POST - Get recipe recommendations based on scraps",
            "/health": "GET - Check API health"
        }
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "data_loaded": recipe_df is not None,
        "num_recipes": len(recipe_df) if recipe_df is not None else 0
    }


@app.post("/recommend", response_model=List[RecipeResponse])
async def recommend(request: RecommendationRequest):
    """Get recipe recommendations based on a text query."""
    try:
        query = request.query
        
        # Apply scrap mapping if enabled
        if request.use_scrap_mapping:
            # Split query into words and map scraps
            words = query.split()
            mapped_words = map_scraps_to_ingredients(words)
            query = " ".join(mapped_words)
        
        recommendations = get_recipe_recommendations(query, request.top_k)
        return recommendations
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/recommend-from-scraps", response_model=List[RecipeResponse])
async def recommend_from_scraps(request: ScrapRecommendationRequest):
    """Get recipe recommendations based on a list of scraps."""
    try:
        # Map scraps to ingredients
        ingredients = map_scraps_to_ingredients(request.scraps)
        
        # Create query from ingredients
        query = " ".join(ingredients)
        
        # Get recommendations
        recommendations = get_recipe_recommendations(query, request.top_k)
        return recommendations
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
