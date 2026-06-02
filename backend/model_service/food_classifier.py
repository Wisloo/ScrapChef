"""
Food image classification service using Gemini API.
"""

import os
import logging
import requests
from typing import List, Dict

class FoodClassifier:
    def __init__(self):
        from transformers import pipeline
        self.logger = logging.getLogger(__name__)
        self.classifier = pipeline('image-classification', model='nateraw/food')
        self.logger.info('Food classifier initialized with HuggingFace')

    def classify(self, image_path: str) -> List[Dict[str, str]]:
        try:
            if not os.path.exists(image_path):
                raise FileNotFoundError(f'Image not found: {image_path}')

            self.logger.info(f'Classifying image: {image_path}')
            results = self.classifier(image_path)
            return self._process_results(results)
        except Exception as e:
            self.logger.error(f'Classification failed: {str(e)}')
            raise

    def _process_results(self, results: List[Dict]) -> List[Dict[str, str]]:
        try:
            # Map food items to their scrap counterparts
            SCRAP_MAP = {
                'banana': 'banana peel',
                'orange': 'orange peel', 
                'apple': 'apple core',
                'carrot': 'carrot tops',
                'onion': 'onion skin'
            }
            
            processed = []
            for pred in results:
                label = SCRAP_MAP.get(pred['label'].lower(), pred['label'])
                processed.append({'label': label, 'score': pred['score']})
            return processed
            
        except Exception as e:
            self.logger.error(f'Error processing results: {str(e)}')
            return []
