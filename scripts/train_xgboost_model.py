#!/usr/bin/env python
"""
Train XGBoost relevance model for recipe recommendations.
Uses recipe_features.csv to train a model that predicts recipe ratings.
"""

import pandas as pd
import numpy as np
import xgboost as xgb
import os
from sklearn.model_selection import train_test_split

# Paths
FEATURE_MATRIX_PATH = 'vector_store/recipe_features.csv'
MODEL_PATH = 'vector_store/xgboost_relevance_model.json'
MAX_ROWS = 50000  # Reduced for faster training

def load_features():
    """Load the feature matrix with chunked reading and subsampling."""
    if not os.path.exists(FEATURE_MATRIX_PATH):
        raise FileNotFoundError(f"Feature matrix not found at {FEATURE_MATRIX_PATH}")
    
    chunks = []
    chunk_size = 10000  # Smaller chunks for progress visibility
    
    print("[INFO] Reading feature matrix in chunks...")
    total_rows = 0
    for chunk in pd.read_csv(FEATURE_MATRIX_PATH, low_memory=False, on_bad_lines='skip', chunksize=chunk_size):
        # Convert numeric columns to float32 to reduce memory usage
        numeric_cols = chunk.select_dtypes(include=['float64']).columns
        chunk = chunk.astype({col: 'float32' for col in numeric_cols})
        chunks.append(chunk)
        total_rows += len(chunk)
        print(f"[INFO] Loaded {total_rows} rows so far...")
        if total_rows >= MAX_ROWS:
            print(f"[INFO] Reached MAX_ROWS limit ({MAX_ROWS}), stopping...")
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
    
    # Split data
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Create DMatrix
    dtrain = xgb.DMatrix(X_train, label=y_train)
    dval = xgb.DMatrix(X_val, label=y_val)
    
    # XGBoost parameters
    params = {
        'objective': 'reg:squarederror',
        'eval_metric': 'rmse',
        'max_depth': 6,
        'learning_rate': 0.1,
        'n_estimators': 100,
        'subsample': 0.8,
        'colsample_bytree': 0.8,
        'random_state': 42,
    }
    
    # Train model
    print("[INFO] Training XGBoost model...")
    model = xgb.train(
        params,
        dtrain,
        num_boost_round=100,
        evals=[(dtrain, 'train'), (dval, 'val')],
        early_stopping_rounds=10,
        verbose_eval=10
    )
    
    return model

def main():
    print("[INFO] Loading feature matrix...")
    df, target_col = load_features()
    print(f"[INFO] Loaded feature matrix with shape {df.shape}")
    print(f"[INFO] Target column: {target_col}")
    
    print("[INFO] Training XGBoost model...")
    model = train_model(df, target_col)
    
    print(f"[INFO] Saving model to {MODEL_PATH}...")
    model.save_model(MODEL_PATH)
    print("[INFO] Model training complete!")
    
    # Test prediction
    print("[INFO] Testing model prediction...")
    feature_cols = [col for col in df.columns if col != target_col]
    X_sample = df[feature_cols].head(5).astype(np.float32).values
    dtest = xgb.DMatrix(X_sample)
    predictions = model.predict(dtest)
    print(f"[INFO] Sample predictions: {predictions}")

if __name__ == "__main__":
    main()
