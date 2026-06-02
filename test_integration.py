#!/usr/bin/env python
"""
Integration test for the ScrapChef backend API.
Tests the /recommendations endpoint with sample data.
"""

import requests
import json

def test_recommendations_endpoint():
    """Test the recommendations endpoint with a sample recipe ID."""
    base_url = "http://localhost:8000"
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("✓ Health check passed")
        else:
            print(f"✗ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"✗ Health check failed: {e}")
        return False
    
    # Test recommendations endpoint
    test_recipe_id = "12345"
    params = {"recipe_id": test_recipe_id, "n": 3}
    
    try:
        response = requests.get(f"{base_url}/recommendations", params=params, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            if "recommendations" in data and isinstance(data["recommendations"], list):
                print(f"✓ Recommendations endpoint successful. Returned {len(data['recommendations'])} recipes.")
                for i, rec in enumerate(data["recommendations"]):
                    print(f"  Recipe {i+1}: ID={rec.get('recipe_id')}, Title={rec.get('title', 'N/A')}")
                return True
            else:
                print(f"✗ Unexpected response format: {data}")
                return False
        else:
            print(f"✗ Recommendations endpoint failed: {response.status_code}")
            print(f"  Response: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("✗ Recommendations endpoint timed out")
        return False
    except requests.exceptions.RequestException as e:
        print(f"✗ Recommendations endpoint error: {e}")
        return False

if __name__ == "__main__":
    print("Running ScrapChef integration tests...")
    success = test_recommendations_endpoint()
    if success:
        print("\n✓ All integration tests passed!")
    else:
        print("\n✗ Some integration tests failed.")