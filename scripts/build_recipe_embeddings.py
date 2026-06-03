#!/usr/bin/env python
import os
import pandas as pd
import numpy as np
from tqdm import tqdm
from sentence_transformers import SentenceTransformer
import json

DATASET_DIR = "dataset/foodcom"
RECIPES_CSV = os.path.join(DATASET_DIR, "recipes_cleaned.csv")
VECTOR_STORE = "vector_store"
os.makedirs(VECTOR_STORE, exist_ok=True)

print("[INFO] Loading recipes dataset...")
# Use python engine with tolerant parsing for the CSV
df = pd.read_csv(RECIPES_CSV, engine='python', on_bad_lines='skip', encoding='latin1', sep=';')

# Determine the text column containing ingredient information
TEXT_COL = (
    "RecipeIngredientParts"
    if "RecipeIngredientParts" in df.columns
    else ("ingredients" if "ingredients" in df.columns else "instructions")
)

print(f"[INFO] Using column '{TEXT_COL}' for embeddings")

# Initialize local SBERT model
embedder = SentenceTransformer('all-MiniLM-L6-v2')
print("[INFO] Using local SentenceTransformer model.")

# Process recipes
print("[INFO] Generating embeddings...")
embeddings = []
recipe_ids = []
recipe_names = []

for _, row in tqdm(df.iterrows(), total=len(df)):
    text = str(row[TEXT_COL]).strip()
    if text:
        embedding = embedder.encode(text)
        embeddings.append(embedding.tolist())
        recipe_ids.append(int(row['RecipeId']))
        # Store name for later lookup (fallback to generic name if missing)
        recipe_names.append(row['Name'] if 'Name' in row else f"Recipe_{row['RecipeId']}")

# Save embeddings as .npy (float32 for efficient loading without allow_pickle)
np.save(os.path.join(VECTOR_STORE, "recipe_embeddings.npy"), np.array(embeddings, dtype=np.float32))
# Save recipe IDs
with open(os.path.join(VECTOR_STORE, "recipe_ids.json"), "w") as f:
    json.dump(recipe_ids, f)
# Save recipe names for lookup
with open(os.path.join(VECTOR_STORE, "recipe_names.json"), "w") as f:
    json.dump(recipe_names, f)

print(f"[INFO] Saved {len(recipe_ids)} recipe embeddings to {VECTOR_STORE}/")
print("[INFO] Embedding generation complete")