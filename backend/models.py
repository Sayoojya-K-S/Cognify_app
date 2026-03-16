from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime, timezone
from database import Base

class SimplifiedTextDB(Base):
    __tablename__ = "simplified_texts"

    id = Column(Integer, primary_key=True, index=True)
    original_text = Column(String, index=True)
    summary = Column(String)
    simplified_text = Column(Text)
    bullet_notes = Column(Text)  # We will store notes as a JSON string
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class QuizDB(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    original_text = Column(String, index=True)
    quiz_data = Column(Text) # Storing full quiz response as JSON string
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
