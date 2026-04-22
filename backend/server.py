import os
import io
import logging
import base64
import asyncio
from datetime import datetime, timedelta, timezone

from fastapi import FastAPI, HTTPException
import google.generativeai as genai
import PIL.Image

# Configuration
GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY', '')
if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)

app = FastAPI()

# ── Gemini helpers ────────────────────────────────────────────────────────────
def _gemini(system: str = ""):
    """Returns the Gemini model."""
    return genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=system or None,
    )

async def _gemini_text(prompt: str, system: str = "") -> str:
    model = _gemini(system)
    response = await asyncio.to_thread(model.generate_content, prompt)
    return response.text.strip()

async def _gemini_vision(prompt: str, image_base64: str, system: str = "") -> str:
    model = _gemini(system)
    # Remove header if present (e.g., data:image/png;base64,)
    if "," in image_base64:
        image_base64 = image_base64.split(",")[-1]
    img_bytes = base64.b64decode(image_base64)
    img = PIL.Image.open(io.BytesIO(img_bytes))
    response = await asyncio.to_thread(model.generate_content, [prompt, img])
    return response.text.strip()

@app.get("/")
async def root():
    return {
        "status": "online", 
        "message": "Household COO Backend is live",
        "api_configured": bool(GOOGLE_API_KEY)
    }

# This section allows Railway to start the server properly
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)