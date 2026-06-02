import json
import logging
import os
import base64
from typing import Any, Dict
from openai import OpenAI

MODEL_NAME = "openrouter/free"
_CLIENT = None

def _get_inference_client():
    global _CLIENT
    if _CLIENT is None:
        _CLIENT = OpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=os.getenv("OPENROUTER_API_KEY"),
        )
    return _CLIENT

def _build_prompt() -> str:
    return (
        "Classify the food scrap in the image.\n"
        "Return ONLY a JSON object with keys: label, confidence.\n"
        "Label should be a short noun phrase (e.g., 'banana peel', 'onion skin').\n"
        "Confidence should be a number between 0 and 1.\n"
        "If unsure, return label 'unknown scrap' with low confidence."
    )

def _encode_image(image_path: str) -> str:
    """Encode image to base64 string."""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def classify_image(image_path: str) -> Dict[str, Any]:
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Image not found: {image_path}")

    client = _get_inference_client()
    prompt = _build_prompt()
    
    # Encode image to base64
    base64_image = _encode_image(image_path)

    # Prepare inputs for OpenRouter API (OpenAI-compatible)
    response = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{base64_image}"
                        }
                    },
                    {"type": "text", "text": prompt},
                ],
            }
        ],
    )

    # Parse response
    if not response.choices or len(response.choices) == 0:
        raise ValueError(f"No choices in response. Response: {response}")
    
    output_text = response.choices[0].message.content
    try:
        parsed = json.loads(output_text)
        label = parsed.get("label", "unknown scrap")
        confidence = parsed.get("confidence", 0.0)
    except json.JSONDecodeError:
        label = "unknown scrap"
        confidence = 0.0

    result = {
        "label": label,
        "scrap_label": label.lower().replace(" ", "_"),
        "confidence": confidence,
    }
    return result