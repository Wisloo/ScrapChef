#!/usr/bin/env python
import os
import pandas as pd
import numpy as np
from tqdm import tqdm
from sentence_transformers import SentenceTransformer
import logging
import json

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATASET_DIR = "dataset/foodcom"
RECIPES_CSV = os.path.join(DATASET_DIR, "recipes.csv")
VECTOR_STORE = "vector_store"
EMBEDDINGS_CSV = os.path.join(VECTOR_STORE, "recipe_embeddings.json")
os.makedirs(VECTOR_STORE, exist_ok=True)

print("[INFO] Loading recipes dataset...")
df = pd.read_csv(RECIPES_CSV)

# Determine the text column containing ingredient information
TEXT_COL = (
    "RecipeIngredientParts"
    if "RecipeIngredientParts" in df.columns
    else ("ingredients" if "ingredients" in df.columns else "instructions")
)

# Initialize local model
embedder = SentenceTransformer('all-MiniLM-L6-v2')
print("[INFO] Using local SentenceTransformer model.")

# Process recipes
print("[INFO] Generating embeddings...")
embeddings = []
for _, row in tqdm(df.iterrows(), total=len(df)):
    text = str(row[TEXT_COL]).strip()
    if text:
        embedding = embedder.encode(text)
        embeddings.append({
            "recipe_id": row['RecipeId'],
            "embedding": embedding.tolist()
        })

# Save embeddings
print("[INFO] Saving embeddings...")
with open(EMBEDDINGS_CSV, 'w') as f:
    json.dump(embeddings, f)

print("[INFO] Embedding generation complete")