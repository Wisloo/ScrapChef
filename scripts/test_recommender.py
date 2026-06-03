#!/usr/bin/env python
""" Test script for SBERT-based recipe recommender. Loads precomputed embeddings and tests similarity search. """  

import json  
import numpy as np  
from sentence_transformers import SentenceTransformer  
from sklearn.metrics.pairwise import cosine_similarity  

def load_embeddings():  
    """Load precomputed SBERT embeddings and recipe IDs."""  
    embeddings = np.load('vector_store/recipe_embeddings.npy', allow_pickle=True)  
    with open('vector_store/recipe_ids.json', 'r') as f:  
        recipe_ids = json.load(f)  
    return embeddings, recipe_ids  

def get_recipe_name(recipe_id):  
    # Assuming you have a function to get recipe name from ID  
    # Replace this with your actual implementation  
    recipe_names = {  
        136471: "Tomato Soup",  
        17877: "Grilled Cheese",  
        # Add more recipe names here  
    }  
    return recipe_names.get(recipe_id, "Unknown Recipe")  

def recommend(scrap_text, weight=None, top_k=5, max_weight=500.0):  
    # Load recipe metadata (cached)  
    from load_recipe_metadata import load_recipe_metadata  
    _RECIPE_METADATA = load_recipe_metadata()  
    
    # Load SBERT model  
    model = SentenceTransformer('all-MiniLM-L6-v2')  
    # Encode the query  
    query_emb = model.encode([scrap_text])  
    # Load embeddings and IDs  
    embeddings, recipe_ids = load_embeddings()  
    # Compute cosine similarity  
    sims = cosine_similarity(query_emb, embeddings)[0]  
    # Optional: adjust by weight  
    if weight is not None:  
        # Normalize weight to [0, 1] and multiply with similarity  
        weight_factor = min(weight / max_weight, 1.0)  # cap at 1.0  
        sims = sims * (0.5 + 0.5 * weight_factor)  # example: boost by weight  
    # Get top indices  
    top_idx = np.argsort(sims)[::-1][:top_k]  
    # Return results  
    return [(recipe_ids[i], sims[i], get_recipe_name(recipe_ids[i])) for i in top_idx]  

def main():  
    # Example test cases  
    test_cases = [  
        ("tomato, onion, garlic", 200),  
        ("bread, cheese, ham", 150),  
        ("apple, banana, oats", 100),  
        ("chicken, rice, broccoli", 300),  
    ]  
    for scrap, weight in test_cases:  
        print(f"\n--- Testing scrap: '{scrap}' with weight {weight}g ---")  
        results = recommend(scrap, weight=weight, top_k=5)  
        for recipe_id, score, name in results:  
            print(f" Recipe ID: {recipe_id}, Name: {name}, Similarity: {score:.4f}")  

if __name__ == '__main__':  
    main()