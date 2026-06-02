#!/usr/bin/env python3
import json
import pandas as pd
import os

INPUT_CSV = "dataset/foodcom/recipes.csv"
OUTPUT_JSON = "vector_store/recipe_metadata.json"

def extract_metadata():
    """Extract recipe IDs and names from the CSV and save as JSON Lines."""
    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    chunk_size = 5000  # adjust based on available memory
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f_out:
        for chunk in pd.read_csv(INPUT_CSV, chunksize=chunk_size, usecols=["RecipeId", "Name"]):
            for _, row in chunk.iterrows():
                entry = {"id": int(row["RecipeId"]), "name": str(row["Name"])}
                f_out.write(json.dumps(entry) + "\n")
    print(f"Saved recipe metadata to {OUTPUT_JSON}")

if __name__ == "__main__":
    extract_metadata()