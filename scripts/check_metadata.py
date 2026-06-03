#!/usr/bin/env python3
import json
import sys

def check_metadata():
    """Check the first few entries of the metadata file."""
    with open('vector_store/recipe_metadata.json', 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i >= 3:  # Just show first 3 entries
                break
            entry = json.loads(line.strip())
            print(f"Entry {i+1}:")
            print(f"  ID: {entry.get('id', 'N/A')}")
            print(f"  Name: {entry.get('name', 'N/A')}")
            print(f"  Keys: {list(entry.keys())}")
            print()

if __name__ == '__main__':
    check_metadata()