#!/usr/bin/env python
"""
Train a minimal XGBoost model using a small subset of data for quick setup.
This creates a functional model to get the backend running quickly.
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import os

# Paths
FEATURE_MATRIX_PATH = 'vector_store/recipe_features.csv'
MODEL_PATH = 'vector_store/xgboost_relevance_model.json'
MAX_ROWS = 5000  # Very small subset for quick training

def load_features():
    """Load a small subset of the feature matrix."""
    if not os.path.exists(FEATURE_MATRIX_PATH):
        raise FileNotFoundError(f"Feature matrix not found at {FEATURE_MATRIX_PATH}")
    
    print(f"[INFO] Loading first {MAX_ROWS} rows from feature matrix...")
    df = pd.read_csv(FEATURE_MATRIX_PATH, nrows=MAX_ROWS, low_memory=False, on_bad_lines='skip')
    df.columns = df.columns.str.strip()
    print(f"[INFO] Loaded {len(df)} rows")
    
    # Determine target column
    possible_targets = [col for col in df.columns if 'rating' in col.lower()]
    if possible_targets:
        target_col = possible_targets[0]
    elif 'AggregatedRating' in df.columns:
        target_col = 'AggregatedRating'
    else:
        raise KeyError("Target column (AggregatedRating) not found in feature matrix.")
        
    return df, target_col

def train_model(df, target_col):
    """Train XGBoost model to predict recipe ratings."""
    # Prepare features and target
    feature_cols = [col for col in df.columns if col != target_col]
    X = df[feature_cols].astype(np.float32).values
    y = df[target_col].astype(np.float32).values
    
    # Filter out rows with missing target values
    mask = ~np.isnan(y)
    X = X[mask]
    y = y[mask]
    
    print(f"[INFO] Training with {len(X)} samples and {len(feature_cols)} features")
    
    # Create DMatrix
    dtrain = xgb.DMatrix(X, label=y)
    
    # XGBoost parameters - simplified for quick training
    params = {
        'objective': 'reg:squarederror',
        'max_depth': 3,
        'learning_rate': 0.1,
        'n_estimators': 10,
        'random_state': 42,
    }
    
    # Train model
    print("[INFO] Training XGBoost model (minimal)...")
    model = xgb.train(params, dtrain, num_boost_round=10)
    
    return model

def main():
    print("[INFO] Starting minimal model training...")
    df, target_col = load_features()
    print(f"[INFO] Target column: {target_col}")
    
    model = train_model(df, target_col)
    
    print(f"[INFO] Saving model to {MODEL_PATH}...")
    model.save_model(MODEL_PATH)
    print("[INFO] Minimal model training complete!")
    
    # Test prediction
    feature_cols = [col for col in df.columns if col != target_col]
    X_sample = df[feature_cols].head(3).astype(np.float32).values
    dtest = xgb.DMatrix(X_sample)
    predictions = model.predict(dtest)
    print(f"[INFO] Sample predictions: {predictions}")

if __name__ == "__main__":
    main()
