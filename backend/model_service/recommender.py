import pandas as pd
import numpy as np
import xgboost as xgb

def get_similar_recipes(model, df, recipe_id, n=5):
    """Return the top‑N similar recipes for a given recipe_id."""
    # Ensure recipe_id is an integer
    try:
        recipe_id = int(recipe_id)
    except (ValueError, TypeError):
        return []

    # Verify the recipe exists
    if not (df['RecipeId'] == recipe_id).any():
        return []

    # Identify the target column (e.g., "AggregatedRating")
    target_col = None
    for col in df.columns:
        if 'rating' in col.lower():
            target_col = col
            break
    if target_col is None:
        target_col = 'AggregatedRating'  # fallback

    # Define feature columns (exclude RecipeId and the target column)
    feature_cols = [col for col in df.columns if col != 'RecipeId']
    if target_col:
        feature_cols = [col for col in feature_cols if col != target_col]

    # Extract the feature matrix for all recipes
    X = df[feature_cols].astype(np.float32).values

    # Load the model and create a DMatrix
    dtest = xgb.DMatrix(X)
    y_pred = model.predict(dtest)

    # Locate the target row index
    target_idx = df[df['RecipeId'] == recipe_id].index[0]
    target_pred = y_pred[target_idx]

    # Compute distances and get the nearest neighbors (excluding the target itself)
    distances = np.abs(y_pred - target_pred)
    nearest_indices = np.argsort(distances)[1:n+1]  # skip self

    # Build the result list
    recommendations = []
    for i in nearest_indices:
        rec_id = int(df.iloc[i]['RecipeId'])
        score = y_pred[i]
        recommendations.append({
            'recipe_id': rec_id,
            'predicted_rating': float(score)
        })
    return recommendations


def _build_feature_index_map(df):
    return {int(recipe_id): idx for idx, recipe_id in enumerate(df['RecipeId'].tolist())}


def _cosine_similarity(query_vector, matrix):
    query_norm = np.linalg.norm(query_vector)
    if query_norm == 0:
        return np.zeros(matrix.shape[0], dtype=np.float32)
    matrix_norms = np.linalg.norm(matrix, axis=1)
    denom = matrix_norms * query_norm
    denom[denom == 0] = 1e-8
    return np.dot(matrix, query_vector) / denom


def get_recommendations_for_labels_sbert(
    query_embedding,
    recipe_embeddings,
    recipe_ids,
    metadata,
    labels,
    n=5,
):
    """Return top-N recipes for label query using SBERT similarity only (no XGBoost)."""
    if query_embedding is None or recipe_embeddings.size == 0:
        return []

    scores = _cosine_similarity(query_embedding, recipe_embeddings)
    if scores.size == 0:
        return []

    # Get top N indices based on similarity scores
    top_indices = np.argsort(-scores)[:n]

    label_text = ", ".join(labels)
    recommendations = []
    for idx in top_indices:
        recipe_id = int(recipe_ids[idx])
        similarity_score = float(scores[idx])
        meta = metadata.get(str(recipe_id), {})
        title = meta.get("name") or f"Recipe {recipe_id}"
        recommendations.append({
            "recipe_id": recipe_id,
            "predicted_rating": similarity_score,
            "title": title,
            "summary": f"Suggested for scraps like {label_text}.",
            "ingredients": labels,
            "matchReason": f"Matches scraps: {label_text}.",
            "chefNote": None,
        })

    return recommendations


def get_recommendations_for_labels(
    model,
    df,
    target_col,
    query_embedding,
    recipe_embeddings,
    recipe_ids,
    metadata,
    labels,
    n=5,
    candidate_k=200,
):
    """Return top-N recipes for label query using SBERT + XGBoost ranking."""
    if query_embedding is None or recipe_embeddings.size == 0:
        return []

    scores = _cosine_similarity(query_embedding, recipe_embeddings)
    if scores.size == 0:
        return []

    candidate_count = min(candidate_k, scores.size)
    candidate_indices = np.argpartition(-scores, candidate_count - 1)[:candidate_count]

    feature_index = _build_feature_index_map(df)

    candidate_rows = []
    candidate_ids = []
    for idx in candidate_indices:
        recipe_id = int(recipe_ids[idx])
        row_index = feature_index.get(recipe_id)
        if row_index is None:
            continue
        candidate_rows.append(row_index)
        candidate_ids.append(recipe_id)

    if not candidate_rows:
        return []

    feature_cols = [col for col in df.columns if col != 'RecipeId']
    if target_col in feature_cols:
        feature_cols.remove(target_col)

    X = df.iloc[candidate_rows][feature_cols].astype(np.float32).values
    dtest = xgb.DMatrix(X)
    y_pred = model.predict(dtest)

    ranked = sorted(
        zip(candidate_ids, y_pred.tolist()),
        key=lambda item: item[1],
        reverse=True,
    )[:n]

    label_text = ", ".join(labels)
    recommendations = []
    for recipe_id, score in ranked:
        meta = metadata.get(str(recipe_id), {})
        title = meta.get("name") or f"Recipe {recipe_id}"
        recommendations.append({
            "recipe_id": recipe_id,
            "predicted_rating": float(score),
            "title": title,
            "summary": f"Suggested for scraps like {label_text}.",
            "ingredients": labels,
            "matchReason": f"Matches scraps: {label_text}.",
            "chefNote": None,
        })

    return recommendations