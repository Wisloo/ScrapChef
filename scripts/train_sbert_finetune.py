#!/usr/bin/env python
"""Fine-tune SBERT on the recipe dataset and export the model to TensorFlow Lite."""

import os
import pandas as pd
import tensorflow as tf
from tqdm import tqdm
from torch.utils.data import DataLoader

from sentence_transformers import SentenceTransformer, InputExample, losses

# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
DATASET_PATH = "dataset/foodcom/recipes_cleaned.csv"
OUTPUT_MODEL_DIR = "assets/models/sbert_finetuned"
OUTPUT_TFLITE_PATH = "assets/models/sbert.tflite"
MAX_TRAIN_ROWS = None  # use all rows
BATCH_SIZE = 128  # Increased from 64
GRADIENT_ACCUMULATION_STEPS = 2  # New: Accumulate gradients over 2 steps
EPOCHS = 1
LEARNING_RATE = 2e-5

# Enable mixed precision training
tf.keras.mixed_precision.set_global_policy('mixed_float16')

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
def load_training_examples():
    """Load a limited number of recipes and create training pairs."""
    print(f"Loading data from {DATASET_PATH}")
    # Use latin-1 encoding to handle any encoding issues
    df = pd.read_csv(DATASET_PATH, nrows=MAX_TRAIN_ROWS, encoding='latin-1', sep=';')
    examples = []
    for _, row in df.iterrows():
        name = str(row.get("Name", "")).strip()
        desc = str(row.get("Description", "")).strip()
        if not name:
            continue
        # Use the recipe name and its description as a positive pair.
        # If description is missing we duplicate the name so the model still sees a pair.
        text2 = desc if desc else name
        # Label 1.0 indicates maximum similarity for positive pairs
        examples.append(InputExample(texts=[name, text2], label=1.0))
    print(f"Created {len(examples)} training examples")
    return examples

def fine_tune_sbert(examples):
    """Fine-tune a small pretrained SBERT model."""
    model_name = "distilbert-base-uncased"
    print(f"Loading pretrained model: {model_name}")
    model = SentenceTransformer(model_name)

    train_dataloader = DataLoader(examples, shuffle=True, batch_size=BATCH_SIZE)
    train_loss = losses.CosineSimilarityLoss(model)

    print("Starting fine-tuning...")
    model.fit(
        train_objectives=[(train_dataloader, train_loss)],
        epochs=EPOCHS,
        warmup_steps=100,
        optimizer_params={"lr": LEARNING_RATE},
        output_path=OUTPUT_MODEL_DIR,
        show_progress_bar=True,
    )
    print(f"Fine-tuned model saved to {OUTPUT_MODEL_DIR}")
    return model

def export_to_tflite():
    """Convert the fine-tuned SBERT model to TensorFlow Lite."""
    print("Loading fine-tuned model for TFLite export...")
    model = SentenceTransformer(OUTPUT_MODEL_DIR)

    # Extract the underlying transformer and tokenizer.
    bert_model = model[0]
    tokenizer = model.tokenizer

    class SBERTEncoder(tf.Module):
        def __init__(self, bert_model, tokenizer):
            self.bert_model = bert_model
            self.tokenizer = tokenizer

        @tf.function(input_signature=[tf.TensorSpec(shape=[None], dtype=tf.string)])
        def __call__(self, text_input):
            def encode_single(text):
                enc = self.tokenizer(
                    text.numpy().decode("utf-8"),
                    max_length=128,
                    padding="max_length",
                    truncation=True,
                    return_tensors="tf",
                )
                return enc["input_ids"], enc["attention_mask"]

            input_ids, attention_mask = tf.py_function(
                func=encode_single, inp=[text_input], Tout=[tf.int32, tf.int32]
            )
            input_ids.set_shape([None, 128])
            attention_mask.set_shape([None, 128])
            outputs = self.bert_model(input_ids, attention_mask=attention_mask)
            embeddings = tf.reduce_mean(outputs.last_hidden_state, axis=1)
            return embeddings

    encoder = SBERTEncoder(bert_model, tokenizer)

    # Test the encoder quickly.
    test_out = encoder(tf.constant(["hello world"]))
    print(f"Test output shape: {test_out.shape}")

    saved_model_path = os.path.join(OUTPUT_MODEL_DIR, "saved_model")
    tf.saved_model.save(encoder, saved_model_path)
    print(f"Saved SavedModel to {saved_model_path}")

    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float32]
    tflite_model = converter.convert()

    with open(OUTPUT_TFLITE_PATH, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite model written to {OUTPUT_TFLITE_PATH}")
    print(f"Model size: {os.path.getsize(OUTPUT_TFLITE_PATH) / (1024 * 1024):.2f} MiB")

if __name__ == "__main__":
    # Ensure output directories exist.
    os.makedirs(OUTPUT_MODEL_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(OUTPUT_TFLITE_PATH), exist_ok=True)

    training_examples = load_training_examples()
    fine_tune_sbert(training_examples)
    export_to_tflite()