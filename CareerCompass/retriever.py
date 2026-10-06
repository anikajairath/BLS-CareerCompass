print("RETRIEVER SCRIPT STARTED", flush=True)

import json
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity


# Load chunks
with open("careercompass_chunks.json", "r", encoding="utf-8") as f:
    chunks = json.load(f)


# Load saved embeddings
embeddings = np.load("careercompass_embeddings.npy")


# Load embedding model
model = SentenceTransformer("all-MiniLM-L6-v2")


def retrieve(query, top_k=3):

    # Convert user question into an embedding
    query_embedding = model.encode([query])

    # Compare question with all stored chunks
    similarities = cosine_similarity(
        query_embedding,
        embeddings
    )[0]

    # Get indexes of the most similar chunks
    top_indices = np.argsort(similarities)[-top_k:][::-1]

    results = []

    for index in top_indices:

        results.append({
            "OCC_CODE": chunks[index]["OCC_CODE"],
            "OCC_TITLE": chunks[index]["OCC_TITLE"],
            "text": chunks[index]["text"],
            "similarity": similarities[index]
        })

    return results


# Test retrieval
query = "Do you think software development is a good field?"

results = retrieve(query, top_k=3)

for result in results:

    print("\n" + "=" * 60)
    print(result["OCC_TITLE"])
    print("Similarity:", round(result["similarity"], 3))
    print("-" * 60)
    print(result["text"])