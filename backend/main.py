import os
import sys
import json
from dotenv import load_dotenv

# Ensure the backend directory is in the Python path regardless of where Uvicorn is run from
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

load_dotenv()  # Load environment variables from .env file
import logging
from typing import List
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from openai import AsyncOpenAI
from sqlalchemy.orm import Session
from database import engine, get_db
import models
from database import engine
from models import Base

Base.metadata.create_all(bind=engine)
# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Cognify AI API", description="AI Backend for Cognitive Processing layer.")

# Create database tables
models.Base.metadata.create_all(bind=engine)

# Enable CORS for Flutter apps (Web/Simulator cross-origin)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Groq Cloud
groq_api_key = os.getenv("XAI_API_KEY")
if groq_api_key == default_api_key:
    logger.warning("Using default API key placeholder. Please set GROQ_API_KEY environment variable.")

# ----------------- Models -----------------

class ProcessRequest(BaseModel):
    text: str = Field(..., min_length=10)
    api_key: str | None = None  # Allow overriding key per request

class SimplifyResponse(BaseModel):
    summary: str
    simplified_text: str
    bullet_notes: List[str]

class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer_index: int
    explanation: str

class QuizResponse(BaseModel):
    quiz_questions: List[QuizQuestion]

# ----------------- Prompts & Configuration -----------------

SYSTEM_INSTRUCTION = (
    "You are an expert special education teacher and linguistic simplifier. "
    "Your job is to transform standard texts into accessible, highly readable learning materials "
    "for students with cognitive learning difficulties. "
    "Use short sentences, active voice, avoid idioms, and keep paragraphs short. "
    "Always return your output as a valid JSON object."
)

def get_client(custom_api_key: str | None = None) -> AsyncOpenAI:
    api_key = custom_api_key if custom_api_key else groq_api_key
    return AsyncOpenAI(
        api_key=api_key,
        base_url="https://api.groq.com/openai/v1"
    )

# ----------------- Routes -----------------

@app.get("/")
def health_check():
    return {"status": "healthy", "service": "Cognify AI Integration Backend (Groq)"}

@app.post("/api/simplify", response_model=SimplifyResponse)
async def simplify_text(req: ProcessRequest, db: Session = Depends(get_db)):
    client = get_client(req.api_key)
    prompt = (
        "Process the following raw text by rewriting it simply, extracting 3-5 bullet points, "
        "and providing a 1-sentence summary.\n\n"
        f"Raw Text:\n{req.text}\n\n"
        "Return the result exactly as a JSON object with this structure: "
        '{"summary": "...", "simplified_text": "...", "bullet_notes": ["...", "..."]}'
    )

    try:
        response = await client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": SYSTEM_INSTRUCTION},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"},
            temperature=0.3
        )
        result_text = response.choices[0].message.content
        result_data = json.loads(result_text)
        
        # Save to database
        db_record = models.SimplifiedTextDB(
            original_text=req.text,
            summary=result_data.get("summary", ""),
            simplified_text=result_data.get("simplified_text", ""),
            bullet_notes=json.dumps(result_data.get("bullet_notes", []))
        )
        db.add(db_record)
        db.commit()
        
        return result_data
    except Exception as e:
        logger.error(f"Error calling Groq: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/quiz", response_model=QuizResponse)
async def generate_quiz(req: ProcessRequest, db: Session = Depends(get_db)):
    client = get_client(req.api_key)
    prompt = (
        "Create an accessible, multiple-choice quiz based on the text. "
        "Generate exactly 3 questions. Each needs exactly 3 options. "
        "Provide a short explanation for the correct answer.\n\n"
        f"Text:\n{req.text}\n\n"
        "Return the result exactly as a JSON object with this structure: "
        '{"quiz_questions": [{"question": "...", "options": ["...", "..."], "correct_answer_index": 0, "explanation": "..."}]}'
    )

    try:
        response = await client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": SYSTEM_INSTRUCTION},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"},
            temperature=0.3
        )
        result_text = response.choices[0].message.content
        result_data = json.loads(result_text)

        # Save to database
        db_record = models.QuizDB(
            original_text=req.text,
            quiz_data=result_text
        )
        db.add(db_record)
        db.commit()

        return result_data
    except Exception as e:
        logger.error(f"Error calling Groq: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/history")
def get_history(db: Session = Depends(get_db)):

    try:
        # Fetch all records from the database
        records = db.query(models.SimplifiedTextDB).all()

        # Convert database rows to JSON
        history = [
            {
                "id": r.id,
                "original_text": r.original_text,
                "summary": r.summary,
                "simplified_text": r.simplified_text,
                "bullet_notes": json.loads(r.bullet_notes)
            }
            for r in records
        ]

        return history

    except Exception as e:
        logger.error(f"Error retrieving history: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve history")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
