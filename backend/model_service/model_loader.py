import os
import pandas as pd
import numpy as np
import xgboost as xgb
from sentence_transformers import SentenceTransformer
import json

# Get the project root directory (two levels up from model_service)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FEATURE_MATRIX_PATH = os.path.join(BASE_DIR, "vector_store", "recipe_features.csv")
MODEL_PATH = os.path.join(BASE_DIR, "vector_store", "xgboost_relevance_model.json")
EMBEDDINGS_PATH = os.path.join(BASE_DIR, "vector_store", "recipe_embeddings.json")
METADATA_PATH = os.path.join(BASE_DIR, "vector_store", "recipe_metadata.json")
METADATA_CACHE_PATH = os.path.join(BASE_DIR, "vector_store", "recipe_metadata_cache.json")
SBERT_MODEL_NAME = "all-MiniLM-L6-v2"

_SBERT_MODEL = None

def load_model():
    """Load the trained XGBoost model."""
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Model not found at {MODEL_PATH}")
    model = xgb.Booster()
    model.load_model(MODEL_PATH)
    return model


def load_sbert_model():
    """Load the SBERT model once for embedding queries."""
    global _SBERT_MODEL
    if _SBERT_MODEL is None:
        _SBERT_MODEL = SentenceTransformer(SBERT_MODEL_NAME)
    return _SBERT_MODEL


def load_recipe_embeddings():
    """Load recipe embeddings from JSON into matrix + recipe_id list."""
    if not os.path.exists(EMBEDDINGS_PATH):
        raise FileNotFoundError(f"Embeddings not found at {EMBEDDINGS_PATH}")

    with open(EMBEDDINGS_PATH, "r", encoding="utf-8") as f:
        raw = json.load(f)

    recipe_ids = []
    vectors = []
    for entry in raw:
        recipe_ids.append(int(entry["recipe_id"]))
        vectors.append(entry["embedding"])

    embeddings = np.array(vectors, dtype=np.float32)
    return embeddings, recipe_ids


def load_recipe_metadata():
    """Load recipe metadata from cache or JSON Lines file."""
    if os.path.exists(METADATA_CACHE_PATH):
        with open(METADATA_CACHE_PATH, "r", encoding="utf-8") as f:
            return json.load(f)

    if not os.path.exists(METADATA_PATH):
        raise FileNotFoundError(f"Metadata not found at {METADATA_PATH}")

    metadata = {}
    with open(METADATA_PATH, "r", encoding="utf-8") as f:
        for line in f:
            entry = json.loads(line.strip())
            metadata[str(entry["id"])] = entry

    with open(METADATA_CACHE_PATH, "w", encoding="utf-8") as f:
        json.dump(metadata, f)

    return metadata

def load_features():
    """Load the feature matrix with chunked reading and subsampling."""
    if not os.path.exists(FEATURE_MATRIX_PATH):
        raise FileNotFoundError(f"Feature matrix not found at {FEATURE_MATRIX_PATH}")
    
    chunks = []
    chunk_size = 50000 # adjust based on available memory
    max_rows = 200000 # maximum number of rows to load
    
    for chunk in pd.read_csv(FEATURE_MATRIX_PATH, low_memory=False, on_bad_lines='skip', chunksize=chunk_size):
        # Convert numeric columns to float32 to reduce memory usage
        numeric_cols = chunk.select_dtypes(include=['float64']).columns
        chunk = chunk.astype({col: 'float32' for col in numeric_cols})
        chunks.append(chunk)
        if len(chunks) * chunk_size >= max_rows:
            break
            
    df = pd.concat(chunks, ignore_index=True)
    df.columns = df.columns.str.strip()
    
    # Determine target column
    possible_targets = [col for col in df.columns if 'rating' in col.lower()]
    if possible_targets:
        target_col = possible_targets[0]
    elif 'AggregatedRating' in df.columns:
        target_col = 'AggregatedRating'
    else:
        raise KeyError("Target column (AggregatedRating) not found in feature matrix.")
        
    return df, target_col