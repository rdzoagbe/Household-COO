import os
import io
import uuid
import logging
import base64
import asyncio
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException, Depends
from google import generativeai as genai
import PIL.Image

# Configuration
GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY', '')
genai.configure(api_key=GOOGLE_API_KEY)

app = FastAPI()

# ── Gemini helpers ────────────────────────────────────────────────────────────
def _gemini(system: str = "") -> genai.GenerativeModel:
    """Return a Gemini 1.5 Flash model, optionally with a system instruction."""
    return genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=system or None,
    )

async def _gemini_text(prompt: str, system: str = "") -> str:
    model = _gemini(system)
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(None, lambda: model.generate_content(prompt))
    return response.text.strip()

async def _gemini_vision(prompt: str, image_base64: str, system: str = "") -> str:
    import io as _io
    model = _gemini(system)
    img_bytes = base64.b64decode(image_base64.split(",")[-1])
    img = PIL.Image.open(_io.BytesIO(img_bytes))
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(None, lambda: model.generate_content([prompt, img]))
    return response.text.strip()

@app.get("/")
async def root():
    return {"status": "online", "message": "Household COO Backend is running"}

# Add your other endpoints (assign, vision, etc.) below using the _gemini helpers above