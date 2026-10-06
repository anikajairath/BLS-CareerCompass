import os
from dotenv import load_dotenv
from google import genai


# Load API key from .env
load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("GEMINI_API_KEY was not found in .env")


# Create Gemini client
client = genai.Client(api_key=api_key)


def generate_answer(question, retrieved_context, career_results):

    prompt = f"""
You are CareerCompass, an AI career research assistant.

Answer the user's question using ONLY the information provided
in the CareerCompass data below.

Do not invent statistics or facts.

If the CareerCompass score is mentioned, explain that it is a
CareerCompass scoring metric based on the project's methodology.
Do not describe it as an official BLS score.

Be clear, concise, and useful for someone researching careers.

USER QUESTION:
{question}


OCCUPATIONAL INFORMATION FROM RAG:
{retrieved_context}


CAREERCOMPASS ENGINE RESULTS:
{career_results}


Give the user a natural-language answer.
"""

    response = client.models.generate_content(
    model="gemini-3.5-flash-lite",
    contents=prompt
)

    return response.text