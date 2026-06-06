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
import httpx
import asyncio

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
ENV_PATH = os.path.join(os.path.dirname(__file__), "..", ".env")

# Load environment variables
from dotenv import load_dotenv
load_dotenv(ENV_PATH)

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")


class RecommendationRequest(BaseModel):
    query: str
    top_k: int = 5
    use_scrap_mapping: bool = True
    user_ingredients: List[str] = None


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


async def verify_and_enhance_recipes(recipes: List[dict], user_ingredients: List[str]) -> List[dict]:
    """Use OpenRouter LLM to verify ingredients and enhance recipe descriptions."""
    if not OPENROUTER_API_KEY:
        # If no API key, return recipes as-is
        return recipes
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Prepare the prompt
            ingredients_str = ", ".join(user_ingredients)
            recipes_text = ""
            for i, recipe in enumerate(recipes):
                recipes_text += f"\nRecipe {i+1}:\n"
                recipes_text += f"Title: {recipe['title']}\n"
                recipes_text += f"Ingredients: {recipe['ingredients']}\n"
                recipes_text += f"Instructions: {recipe.get('instructions', 'N/A')}\n"
            
            prompt = f"""You are a recipe recommendation assistant. The user has these ingredients: {ingredients_str}

I found these recipes using semantic search. Please:
1. Verify which recipes actually contain the user's ingredients (check the ingredients list carefully)
2. For recipes that DO contain the ingredients, provide a brief match reason explaining why they're good matches
3. For recipes that DON'T contain the ingredients, mark them as "INVALID"
4. Return your response in this exact JSON format:
{{
  "verified_recipes": [
    {{
      "index": 0,
      "valid": true,
      "match_reason": "This recipe contains [ingredients] and is a great match because..."
    }},
    {{
      "index": 1,
      "valid": false,
      "match_reason": "This recipe doesn't contain the user's ingredients"
    }}
  ]
}}

{recipes_text}

Respond ONLY with valid JSON, no other text."""

            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "meta-llama/llama-3.2-3b-instruct",
                    "messages": [
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.3,
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"]
                
                # Parse the JSON response
                import re
                json_match = re.search(r'\{.*\}', content, re.DOTALL)
                if json_match:
                    verification_data = json.loads(json_match.group())
                    
                    # Apply verification results
                    for verified in verification_data.get("verified_recipes", []):
                        idx = verified["index"]
                        if idx < len(recipes):
                            if verified["valid"]:
                                recipes[idx]["match_reason"] = verified.get("match_reason", recipes[idx].get("match_reason", ""))
                                recipes[idx]["verified"] = True
                            else:
                                recipes[idx]["verified"] = False
                
                # Filter out invalid recipes
                verified_recipes = [r for r in recipes if r.get("verified", True)]
                return verified_recipes if verified_recipes else recipes
            else:
                print(f"OpenRouter API error: {response.status_code}")
                return recipes
                
    except Exception as e:
        print(f"Error calling OpenRouter: {e}")
        return recipes


async def get_recipe_recommendations(query: str, top_k: int = 5, user_ingredients: List[str] = None) -> List[RecipeResponse]:
    """Get recipe recommendations based on query using semantic search."""
    global model, recipe_df, recipe_embeddings
    
    if model is None or recipe_df is None or recipe_embeddings is None:
        raise HTTPException(status_code=500, detail="Model or data not loaded")
    
    # Encode the query
    query_embedding = model.encode([query])
    
    # Calculate cosine similarity
    similarities = cosine_similarity(query_embedding, recipe_embeddings)[0]
    
    # Get top-k indices (get more for RAG verification)
    retrieval_k = top_k * 3  # Get 3x more for verification
    top_indices = np.argsort(similarities)[::-1][:retrieval_k]
    
    # Prepare response
    recipes_dict = []
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
        
        recipes_dict.append({
            'title': title,
            'ingredients': ingredients,
            'instructions': instructions,
            'similarity_score': float(similarities[idx]),
            'image_url': first_image_url,
            'match_reason': f'Similarity: {float(similarities[idx]) * 100:.1f}%'
        })
    
    # Use RAG to verify and enhance if user ingredients are provided
    print(f"DEBUG: user_ingredients={user_ingredients}, OPENROUTER_API_KEY={'SET' if OPENROUTER_API_KEY else 'NOT SET'}")
    if user_ingredients and OPENROUTER_API_KEY:
        print("DEBUG: Calling verify_and_enhance_recipes")
        recipes_dict = await verify_and_enhance_recipes(recipes_dict, user_ingredients)
    else:
        print("DEBUG: LLM verification skipped - missing user_ingredients or API key")
    
    # Convert to RecipeResponse and limit to top_k
    recommendations = []
    for recipe in recipes_dict[:top_k]:
        recommendations.append(RecipeResponse(
            title=recipe['title'],
            ingredients=recipe['ingredients'],
            instructions=recipe.get('instructions'),
            similarity_score=recipe['similarity_score'],
            image_url=recipe['image_url']
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
            # Extract scrap item from "Recipes using X" format
            query_lower = query.lower().strip()
            if query_lower.startswith("recipes using "):
                scrap_item = query_lower.replace("recipes using ", "").strip()
                if scrap_item in scrap_mapping:
                    query = scrap_mapping[scrap_item]
                else:
                    # Try mapping individual words
                    words = scrap_item.split()
                    mapped_words = map_scraps_to_ingredients(words)
                    query = " ".join(mapped_words)
            elif query_lower in scrap_mapping:
                query = scrap_mapping[query_lower]
            else:
                # Split query into words and map scraps
                words = query.split()
                mapped_words = map_scraps_to_ingredients(words)
                query = " ".join(mapped_words)
        
        recommendations = await get_recipe_recommendations(query, request.top_k, request.user_ingredients)
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
        
        # Get recommendations with RAG verification
        recommendations = await get_recipe_recommendations(query, request.top_k, request.scraps)
        return recommendations
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
