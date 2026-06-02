#!/usr/bin/env python3
import json
import os

CACHE_FILE = "vector_store/recipe_metadata_cache.json"
METADATA_FILE = "vector_store/recipe_metadata.json"

def load_recipe_metadata():
    """
    Loads recipe metadata from JSON Lines file and caches it as a dict.
    Returns a dictionary mapping recipe IDs to metadata dicts.
    """
    # If cache exists, load from it for speed
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)

    # Otherwise, build cache from the JSON Lines file
    metadata = {}
    with open(METADATA_FILE, "r", encoding="utf-8") as f:
        for line in f:
            entry = json.loads(line.strip())
            metadata[entry["id"]] = entry

    # Save cache for future runs
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(metadata, f)

    return metadata