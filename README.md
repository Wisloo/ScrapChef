# ScrapChef

A Flutter application that helps you turn food scraps into delicious recipes using machine learning.

## Features

- **Smart Scrap Classification**: Uses AI to identify food scraps from images
- **Recipe Recommendations**: Get personalized recipe suggestions based on your available scraps
- **Inventory Management**: Keep track of your scraps and save your favorite recipes
- **ML-Powered Recommendations**: Combines SBERT embeddings and XGBoost for accurate recipe matching

## Architecture

### Backend (Python/FastAPI)
- **Model Service**: Provides recipe recommendations using a two-stage approach:
  1. SBERT embeddings for initial candidate retrieval
  2. XGBoost relevance model for ranking
- **API Endpoints**:
  - `GET /health`: Health check
  - `GET /recommendations?recipe_id={id}&n={count}`: Get recipe recommendations

### Frontend (Flutter)
- **State Management**: Uses `AppState` to manage scrap inventory and user data
- **Services**: `RecipeService` bridges the frontend with the backend API
- **UI**: Clean, intuitive interface for scanning, managing scraps, and browsing recipes

## Setup and Installation

### Prerequisites
- Flutter SDK
- Python 3.11
- Docker (optional, for deployment)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ScrapChef.git
   cd ScrapChef
   ```

2. **Backend Setup**
   ```bash
   cd backend
   pip install -r requirements.txt
   python -m scripts.train_recommender  # Prepare model files
   ```
   
   **Environment Variables**: Create a `.env` file in the project root with:
   ```
   OPENROUTER_API_KEY=your_openrouter_api_key_here
   BACKEND_URL=http://localhost:8000
   ```
   Get your free API key from [OpenRouter](https://openrouter.ai/keys)
   
   Then start the server:
   ```bash
   uvicorn backend.main:app --host 0.0.0.0 --port 8000
   ```

3. **Frontend Setup**
   ```bash
   flutter pub get
   flutter run
   ```

### Docker Deployment

1. **Build and run with Docker Compose**
   ```bash
   docker-compose up --build
   ```

2. **Or build individually**
   ```bash
   # Backend
   cd backend
   docker build -t scrapchef-backend .
   docker run -p 8000:8000 scrapchef-backend

   # Frontend (web build)
   flutter build web
   # Serve the build/web directory with any web server
   ```

## Usage

1. **Scan Scraps**: Use the camera to identify food scraps
2. **View Inventory**: See all your logged scraps in the Bin tab
3. **Find Recipes**: Tap "Find Recipes" to get suggestions based on your scraps
4. **Save Recipes**: Save your favorite recipes for later reference

## API Documentation

Once the backend is running, visit `http://localhost:8000/docs` for interactive API documentation.

## Model Details

The recommendation system uses:
- **SBERT**: For semantic similarity between recipes and scraps
- **XGBoost**: For relevance scoring and ranking
- **Feature Matrix**: Pre-computed recipe features for fast inference

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.