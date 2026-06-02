"""
Test script for OpenRouter image classification integration.
"""
import os
import sys
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from backend.model_service.openrouter_classifier import classify_image

def test_openrouter_classification():
    """Test the OpenRouter-based image classification."""
    
    # Check if API key is set
    if not os.getenv("OPENROUTER_API_KEY"):
        print("ERROR: OPENROUTER_API_KEY environment variable not set")
        print("Please set it in your .env file or export it:")
        print("export OPENROUTER_API_KEY=your_key_here")
        return False
    
    # Test with a sample image
    test_image = "test_images/simple_test.jpg"
    
    if not os.path.exists(test_image):
        print(f"ERROR: Test image not found at {test_image}")
        return False
    
    try:
        print(f"Testing classification with {test_image}...")
        result = classify_image(test_image)
        print("Classification successful!")
        print(f"Result: {result}")
        return True
    except Exception as e:
        print(f"ERROR: Classification failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_openrouter_classification()
    sys.exit(0 if success else 1)
