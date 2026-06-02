#!/usr/bin/env python
"""
Train a relevance model using SBERT embeddings for recipe recommendations.
The script loads pre‑computed SBERT embeddings and prepares them for similarity‑based recommendation.
"""

import os
import json
import numpy as np

# Paths
EMBEDDINGS_PATH = 'vector_store/recipe_embeddings.json'
EMBEDDINGS_NPY = 'vector_store/recipe_embeddings.npy'
RECIPE_IDS_JSON = 'vector_store/recipe_ids.json'

# Memory management: limit number of embeddings to load if needed
MAX_EMBEDDINGS = 200000  # Adjust based on available memory

def load_embeddings():
    """Load pre‑computed SBERT embeddings from the JSON file."""
    if not os.path.exists(EMBEDDINGS_PATH):
        raise FileNotFoundError(f"Embeddings not found at {EMBEDDINGS_PATH}")

    with open(EMBEDDINGS_PATH, 'r') as f:
        data = json.load(f)

    # Extract embeddings and recipe IDs
    embeddings = np.array([item['embedding'] for item in data])
    recipe_ids = [item['recipe_id'] for item in data]

    # Optionally truncate to a manageable size
    if len(embeddings) > MAX_EMBEDDINGS:
        embeddings = embeddings[:MAX_EMBEDDINGS]
        recipe_ids = recipe_ids[:MAX_EMBEDDINGS]

    return embeddings, recipe_ids

def save_numpy_embeddings(embeddings, recipe_ids):
    """Save embeddings and IDs in fast‑load formats."""
    np.save(EMBEDDINGS_NPY, embeddings)
    with open(RECIPE_IDS_JSON, 'w') as f:
        json.dump(recipe_ids, f)

def main():
    print("[INFO] Loading pre‑computed SBERT embeddings...")
    embeddings, recipe_ids = load_embeddings()
    print(f"[INFO] Loaded {len(embeddings)} embeddings")

    print("[INFO] Saving embeddings to NumPy format for fast lookup...")
    save_numpy_embeddings(embeddings, recipe_ids)
    print("[INFO] Embeddings saved:")
    print(f"  - {EMBEDDINGS_NPY}")
    print(f"  - {RECIPE_IDS_JSON}")

    print("[INFO] Ready for similarity‑based recommendation using these embeddings.")

if __name__ == "__main__":
    main()