#!/usr/bin/env python
"""Clean up recipes.csv by removing entries with missing essential data."""

import pandas as pd
import os

INPUT_CSV = "dataset/foodcom/recipes.csv"
OUTPUT_CSV = "dataset/foodcom/recipes_cleaned.csv"

def main():
    # Read the CSV file
    df = pd.read_csv(INPUT_CSV)
    print(f"Original shape: {df.shape}")
    
    # Define essential columns that should not be missing/empty
    essential_cols = ['Name', 'Description', 'RecipeIngredientParts', 'RecipeInstructions']
    
    # Count missing values before cleaning
    missing_counts = df[essential_cols].isna().sum()
    print(f"Missing values per essential column:\n{missing_counts}")
    
    # Remove rows where essential columns are missing or empty
    for col in essential_cols:
        df = df[df[col].notna() & (df[col].astype(str).str.strip() != '')]
    
    print(f"After removing missing: {df.shape}")
    
    # Also remove rows with very short descriptions (likely placeholder or incomplete)
    df = df[df['Description'].astype(str).str.len() > 20]
    print(f"After removing short descriptions: {df.shape}")
    
    # Save cleaned CSV
    df.to_csv(OUTPUT_CSV, index=False)
    print(f"Saved cleaned recipes to {OUTPUT_CSV}")

if __name__ == "__main__":
    main()