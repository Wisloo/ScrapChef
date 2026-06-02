#!/usr/bin/env python

"""Data preprocessing for the Food.com recipes dataset.

This script reads ``dataset/foodcom/recipes.csv`` and creates a feature matrix
required for the recommendation model.  At least ten attributes are engineered:

1. ``title_len`` – length of the recipe name (characters)
2. ``num_ingredients`` – number of ingredient entries in ``RecipeIngredientParts``
3. ``cuisine`` – one‑hot encoded categories from ``RecipeCategory`` (split by commas)
4. ``total_time`` – ``TotalTime`` in minutes (numeric, NaN filled with 0)
5. ``rating`` – ``AggregatedRating`` (numeric, NaN filled with 0)
6. ``review_count`` – ``ReviewCount`` (numeric, NaN filled with 0)
7. ``calories`` – ``Calories`` (numeric, NaN filled with 0)
8. ``protein`` – ``ProteinContent`` (numeric, NaN filled with 0)
9. ``fat`` – ``FatContent`` (numeric, NaN filled with 0)
10. ``carbs`` – ``CarbohydrateContent`` (numeric, NaN filled with 0)
11. ``servings`` – ``RecipeServings`` (numeric, NaN filled with 0)

The resulting dataframe is saved as ``vector_store/recipe_features.csv`` for
subsequent model training.
"""

import pandas as pd
import numpy as np
import os
import ast

INPUT_CSV = "dataset/foodcom/recipes.csv"
OUTPUT_CSV = "vector_store/recipe_features.csv"

def count_ingredients(ing_str):
    """Count ingredients from the raw string representation.
    The original CSV stores ingredients as a string that looks like a Python list,
    e.g., 'c("ingredient1", "ingredient2")' or sometimes just a plain string.
    We try to parse it as a Python list; if that fails, we fall back to counting
    commas or treat as a single ingredient.
    """
    if pd.isna(ing_str):
        return 0
    # Remove the leading 'c(' and trailing ')' if present
    s = str(ing_str).strip()
    if s.startswith('c(') and s.endswith(')'):
        s = s[2:-1]
    # Now s should be something like '"ingredient1", "ingredient2"' or empty
    if not s:
        return 0
    # Split by commas that are outside quotes? Simple approach: count commas + 1
    # But we need to handle quoted commas. We'll use a simple heuristic:
    # If the string contains quotes, we assume it's a comma-separated list of quoted items.
    # We'll remove quotes and split by commas.
    # However, the string might already be without quotes.
    # Let's try to parse as a Python list using ast.literal_eval after adding brackets.
    try:
        # If the string looks like a tuple or list, we can evaluate it.
        # But note: the string might be like '"ingredient1", "ingredient2"' (no brackets)
        # We'll wrap it in brackets and try.
        lst = ast.literal_eval('[' + s + ']')
        if isinstance(lst, list):
            return len(lst)
    except Exception:
        pass
    # Fallback: split by commas and count non-empty parts
    parts = [part.strip() for part in s.split(',') if part.strip()]
    return len(parts)

def main():
    # Ensure output directory exists
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
    
    # Read the CSV file in chunks to avoid memory issues
    chunk_size = 5000
    chunks = []
    for chunk in pd.read_csv(INPUT_CSV, chunksize=chunk_size):
        # Feature engineering
        # 1. title_len
        chunk['title_len'] = chunk['Name'].fillna('').apply(len)
        # 2. num_ingredients
        chunk['num_ingredients'] = chunk['RecipeIngredientParts'].apply(count_ingredients)
        # 3. cuisine: we'll create one-hot encoding for the top cuisines later, but for now
        #    we'll extract the first cuisine from RecipeCategory (if multiple, take the first)
        #    and then we can one-hot encode. However, the requirement is to have at least 10 attributes.
        #    We'll create a binary feature for whether the recipe belongs to a certain category.
        #    But to keep it simple and meet the requirement of at least 10 attributes, we'll
        #    create a few categorical features and then one-hot encode them, which will add more than 10.
        #    However, the instructions say "use at least 10 attributes", meaning we need at least 10
        #    features (columns) in the final feature matrix. We can achieve that with the numeric
        #    features we already have and then add a few one-hot encoded columns.
        #    Let's first extract the cuisine categories (split by commas) and then create a binary
        #    column for each of the top 5 cuisines.
        #    We'll do that after processing all chunks to know the top cuisines.
        #    For now, we'll just create a string column with the first cuisine.
        chunk['cuisine'] = chunk['RecipeCategory'].fillna('').apply(
            lambda x: str(x).split(',')[0] if str(x) else ''
        )
        # 4. total_time
        chunk['total_time'] = pd.to_numeric(chunk['TotalTime'], errors='coerce').fillna(0)
        # 5. rating
        chunk['rating'] = pd.to_numeric(chunk['AggregatedRating'], errors='coerce').fillna(0)
        # 6. review_count
        chunk['review_count'] = pd.to_numeric(chunk['ReviewCount'], errors='coerce').fillna(0)
        # 7. calories
        chunk['calories'] = pd.to_numeric(chunk['Calories'], errors='coerce').fillna(0)
        # 8. protein
        chunk['protein'] = pd.to_numeric(chunk['ProteinContent'], errors='coerce').fillna(0)
        # 9. fat
        chunk['fat'] = pd.to_numeric(chunk['FatContent'], errors='coerce').fillna(0)
        # 10. carbs
        chunk['carbs'] = pd.to_numeric(chunk['CarbohydrateContent'], errors='coerce').fillna(0)
        # 11. servings
        chunk['servings'] = pd.to_numeric(chunk['RecipeServings'], errors='coerce').fillna(0)
        
        # Keep only the features we need (including the cuisine string for now)
        features = chunk[
            ['title_len', 'num_ingredients', 'cuisine', 'total_time', 'rating',
             'review_count', 'calories', 'protein', 'fat', 'carbs', 'servings']
        ]
        chunks.append(features)
    
    # Concatenate all chunks
    df_features = pd.concat(chunks, ignore_index=True)
    
    # Now, one-hot encode the cuisine column (we'll keep the top 5 cuisines and group the rest as 'Other')
    cuisine_counts = df_features['cuisine'].value_counts()
    top_cuisines = cuisine_counts.head(5).index.tolist()
    def map_cuisine(c):
        return c if c in top_cuisines else 'Other'
    df_features['cuisine_mapped'] = df_features['cuisine'].apply(map_cuisine)
    # One-hot encode
    cuisine_dummies = pd.get_dummies(df_features['cuisine_mapped'], prefix='cuisine')
    # Drop the original cuisine columns and concatenate the dummies
    df_features = df_features.drop(['cuisine', 'cuisine_mapped'], axis=1)
    df_features = pd.concat([df_features, cuisine_dummies], axis=1)
    
    # Save to CSV
    df_features.to_csv(OUTPUT_CSV, index=False)
    print(f"Saved features to {OUTPUT_CSV} with shape {df_features.shape}")

if __name__ == "__main__":
    main()
