import json
import numpy as np
from sentence_transformers import SentenceTransformer

print("1. Starting...", flush=True)

with open("careercompass_chunks.json", "r", encoding="utf-8") as f:
    chunks = json.load(f)

print("2. Loaded chunks:", len(chunks), flush=True)

print("3. Loading embedding model...", flush=True)

model = SentenceTransformer("all-MiniLM-L6-v2")

print("4. Model loaded!", flush=True)

texts = [chunk["text"] for chunk in chunks]

print("5. Creating embeddings...", flush=True)

embeddings = model.encode(
    texts,
    show_progress_bar=True
)

print("6. Embeddings created!", flush=True)

np.save("careercompass_embeddings.npy", embeddings)

print("7. Saved embeddings!", flush=True)
print("Shape:", embeddings.shape)