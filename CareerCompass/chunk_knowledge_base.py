import json


# Load knowledge base
with open("careercompass_knowledge_base.json", "r", encoding="utf-8") as f:
    documents = json.load(f)


chunks = []

for doc in documents:

    text = doc["text"]

    # Split into smaller pieces
    words = text.split()

    chunk_size = 150

    for i in range(0, len(words), chunk_size):

        chunk_text = " ".join(words[i:i + chunk_size])

        chunks.append({
            "OCC_CODE": doc["OCC_CODE"],
            "OCC_TITLE": doc["OCC_TITLE"],
            "text": chunk_text
        })


# Save chunks
with open("careercompass_chunks.json", "w", encoding="utf-8") as f:
    json.dump(chunks, f, indent=2, ensure_ascii=False)


print(f"Created {len(chunks)} chunks.")