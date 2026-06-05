"""
Integration examples for the Recipe RAG API
Shows how to integrate the API into your application
"""

import requests
import json

API_BASE_URL = "http://localhost:8000"


def get_recipe_recommendations(query: str, top_k: int = 5, use_scrap_mapping: bool = True):
    """
    Get recipe recommendations based on a text query
    
    Args:
        query: Text description of what you want to cook
        top_k: Number of recommendations to return
        use_scrap_mapping: Whether to apply scrap-to-ingredient mapping
    
    Returns:
        List of recipe recommendations with similarity scores
    """
    url = f"{API_BASE_URL}/recommend"
    payload = {
        "query": query,
        "top_k": top_k,
        "use_scrap_mapping": use_scrap_mapping
    }
    
    response = requests.post(url, json=payload)
    response.raise_for_status()
    return response.json()


def get_recommendations_from_scraps(scraps: list, top_k: int = 5):
    """
    Get recipe recommendations based on kitchen scraps
    
    Args:
        scraps: List of scrap items (e.g., ["carrot peel", "garlic skin"])
        top_k: Number of recommendations to return
    
    Returns:
        List of recipe recommendations with similarity scores
    """
    url = f"{API_BASE_URL}/recommend-from-scraps"
    payload = {
        "scraps": scraps,
        "top_k": top_k
    }
    
    response = requests.post(url, json=payload)
    response.raise_for_status()
    return response.json()


def check_api_health():
    """Check if the API is running and healthy"""
    url = f"{API_BASE_URL}/health"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()


# Example usage
if __name__ == "__main__":
    print("=== Recipe RAG API Integration Examples ===\n")
    
    # Check API health
    print("1. Checking API health...")
    try:
        health = check_api_health()
        print(f"   Status: {health['status']}")
        print(f"   Recipes loaded: {health['num_recipes']}")
        print()
    except requests.exceptions.ConnectionError:
        print("   ERROR: API is not running. Start it with: python main.py")
        exit(1)
    
    # Example 1: Get recommendations from text query
    print("2. Getting recommendations from text query...")
    query = "chicken with vegetables"
    recommendations = get_recipe_recommendations(query, top_k=3)
    print(f"   Query: '{query}'")
    for i, recipe in enumerate(recommendations, 1):
        print(f"   {i}. {recipe['title']} (similarity: {recipe['similarity_score']:.3f})")
    print()
    
    # Example 2: Get recommendations from scraps
    print("3. Getting recommendations from kitchen scraps...")
    scraps = ["carrot peel", "garlic skin", "onion skin"]
    recommendations = get_recommendations_from_scraps(scraps, top_k=3)
    print(f"   Scraps: {scraps}")
    for i, recipe in enumerate(recommendations, 1):
        print(f"   {i}. {recipe['title']} (similarity: {recipe['similarity_score']:.3f})")
    print()
    
    # Example 3: Get detailed recipe information
    print("4. Getting detailed recipe information...")
    recommendations = get_recipe_recommendations("pasta with tomato sauce", top_k=1)
    if recommendations:
        recipe = recommendations[0]
        print(f"   Title: {recipe['title']}")
        print(f"   Ingredients: {recipe['ingredients'][:100]}...")
        print(f"   Instructions: {recipe['instructions'][:100]}...")
    print()
