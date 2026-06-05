# Recipe RAG API

A FastAPI-based recipe recommendation system using SBERT (Sentence-BERT) for semantic search and RAG (Retrieval-Augmented Generation) principles.

## Features

- **Semantic Recipe Search**: Find recipes based on natural language queries using SBERT embeddings
- **Scrap-to-Ingredient Mapping**: Automatically map kitchen scraps to their corresponding ingredients
- **Cosine Similarity Retrieval**: Efficient recipe recommendation using pre-computed embeddings
- **FastAPI Backend**: RESTful API with CORS support for easy integration

## Setup

### Prerequisites

- Python 3.8+
- pip

### Installation

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Ensure the following files exist in the `sbert_model/` directory:
   - `df_recipes_with_embeddings.parquet` - Recipe data with pre-computed embeddings
   - `scrap_mapping.json` - Mapping from scrap items to ingredients
   - SBERT model files (model.safetensors, config.json, tokenizer files, etc.)

### Running the API

Start the server:
```bash
python main.py
```

Or using uvicorn directly:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000`

## API Endpoints

### GET `/`
Root endpoint with API information.

### GET `/health`
Health check endpoint. Returns:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "data_loaded": true,
  "num_recipes": 12345
}
```

### POST `/recommend`
Get recipe recommendations based on a text query.

**Request Body:**
```json
{
  "query": "chicken with vegetables",
  "top_k": 5,
  "use_scrap_mapping": true
}
```

**Response:**
```json
[
  {
    "title": "Chicken Vegetable Stir Fry",
    "ingredients": "chicken, broccoli, carrots, soy sauce...",
    "instructions": "Heat oil in a wok...",
    "similarity_score": 0.89
  }
]
```

### POST `/recommend-from-scraps`
Get recipe recommendations based on a list of kitchen scraps.

**Request Body:**
```json
{
  "scraps": ["carrot peel", "garlic skin", "onion skin"],
  "top_k": 5
}
```

**Response:**
```json
[
  {
    "title": "Vegetable Soup",
    "ingredients": "carrots, garlic, onions...",
    "instructions": "Chop vegetables...",
    "similarity_score": 0.85
  }
]
```

## Scrap Mapping

The `scrap_mapping.json` file maps kitchen scraps to their corresponding ingredients:

```json
{
  "carrot peel": "carrots",
  "garlic skin": "garlic",
  "onion skin": "onion",
  "potato peel": "potato",
  "broccoli stalk": "broccoli"
}
```

You can extend this mapping to include more scrap items.

## How It Works

1. **Model Loading**: The SBERT model loads from the `sbert_model/` directory
2. **Embedding Retrieval**: Pre-computed recipe embeddings are loaded from the parquet file
3. **Query Processing**: User queries are encoded using SBERT
4. **Similarity Search**: Cosine similarity is computed between query and recipe embeddings
5. **Top-K Selection**: The most similar recipes are returned with similarity scores

## Integration with Your Application

### Example: Fetch Recommendations

```python
import requests

# Get recommendations from a query
response = requests.post("http://localhost:8000/recommend", json={
    "query": "chicken with vegetables",
    "top_k": 5
})
recipes = response.json()

# Get recommendations from scraps
response = requests.post("http://localhost:8000/recommend-from-scraps", json={
    "scraps": ["carrot peel", "garlic skin"],
    "top_k": 5
})
recipes = response.json()
```

## Next Steps

To enhance the RAG system:

1. **Add Generation Component**: Integrate an LLM (like GPT) to generate personalized recipe descriptions or modifications
2. **Filter by Dietary Restrictions**: Add filters for vegetarian, vegan, gluten-free, etc.
3. **Ingredient Substitution**: Suggest ingredient alternatives based on what's available
4. **Recipe Rating**: Incorporate user ratings to improve recommendations
5. **Caching**: Add Redis or similar for faster response times

## Troubleshooting

**Model not loading**: Ensure all SBERT model files are present in `sbert_model/`

**Embedding column not found**: Check that the parquet file contains an embedding column (named 'embedding', 'embeddings', or similar)

**CORS errors**: The API has CORS enabled for all origins. Adjust the middleware settings if needed.
