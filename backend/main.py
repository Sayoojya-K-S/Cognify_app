from fastapi import FastAPI
from pydantic import BaseModel
import requests

app = FastAPI()

class TextRequest(BaseModel):
    text: str

API_URL = "https://api-inference.huggingface.co/models/google/flan-t5-large"

headers = {
    "Authorization": "Bearer YOUR_NEW_TOKEN"
}

@app.post("/simplify")
def simplify(data: TextRequest):

    prompt = f"Simplify this text:\n{data.text}"

    response = requests.post(
        API_URL,
        headers=headers,
        json={"inputs": prompt}
    )

    result = response.json()

    return {
        "result": result
    }