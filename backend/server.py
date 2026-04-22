#!/usr/bin/env python3
"""
Patches backend/server.py to replace emergentintegrations with google-generativeai.
Run from the ROOT of your Household-COO repo:
    python patch_server.py
"""

import re
from pathlib import Path

SERVER = Path("backend/server.py")
assert SERVER.exists(), "Run this from the repo root — backend/server.py not found"

original = SERVER.read_text(encoding="utf-8")
patched = original

# ── 1. Replace EMERGENT_LLM_KEY variable name with GOOGLE_API_KEY ─────────────
patched = patched.replace(
    "EMERGENT_LLM_KEY = os.environ.get('EMERGENT_LLM_KEY', '')",
    "GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY', '')"
)

# ── 2. Add google-generativeai import after existing imports ──────────────────
IMPORT_ANCHOR = "from datetime import datetime, timedelta, timezone"
GOOGLE_IMPORTS = """from datetime import datetime, timedelta, timezone
import base64
import google.generativeai as genai"""

patched = patched.replace(IMPORT_ANCHOR, GOOGLE_IMPORTS, 1)

# ── 3. Add genai.configure() right after GOOGLE_API_KEY is set ───────────────
patched = patched.replace(
    "GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY', '')",
    "GOOGLE_API_KEY = os.environ.get('GOOGLE_API_KEY', '')\ngenai.configure(api_key=GOOGLE_API_KEY)"
)

# ── 4. Helper function — insert before app = FastAPI() ───────────────────────
HELPER = '''
# ── Gemini helpers ────────────────────────────────────────────────────────────
def _gemini(system: str = "") -> genai.GenerativeModel:
    """Return a Gemini 1.5 Flash model, optionally with a system instruction."""
    return genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=system or None,
    )

async def _gemini_text(prompt: str, system: str = "") -> str:
    import asyncio
    model = _gemini(system)
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(None, lambda: model.generate_content(prompt))
    return response.text.strip()

async def _gemini_vision(prompt: str, image_base64: str, system: str = "") -> str:
    import asyncio
    import PIL.Image
    import io as _io
    model = _gemini(system)
    img_bytes = base64.b64decode(image_base64.split(",")[-1])
    img = PIL.Image.open(_io.BytesIO(img_bytes))
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(None, lambda: model.generate_content([prompt, img]))
    return response.text.strip()

async def _gemini_audio(audio_bytes: bytes, ext: str) -> str:
    """Transcribe audio using Gemini 1.5 Flash multimodal."""
    import asyncio
    mime_map = {
        "webm": "audio/webm", "mp4": "audio/mp4", "m4a": "audio/mp4",
        "mp3": "audio/mpeg", "wav": "audio/wav", "ogg": "audio/ogg",
    }
    mime = mime_map.get(ext, "audio/webm")
    model = _gemini()
    audio_part = {"mime_type": mime, "data": audio_bytes}
    prompt = "Transcribe exactly what is spoken in this audio. Return only the transcript, no commentary."
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(
        None, lambda: model.generate_content([prompt, audio_part])
    )
    return response.text.strip()

'''

patched = patched.replace("app = FastAPI()", HELPER + "app = FastAPI()", 1)

# ── 5. Patch AI ASSIGN ────────────────────────────────────────────────────────
OLD_ASSIGN = '''    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"assign_{user.user_id}_{uuid.uuid4().hex[:6]}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        resp = str(await chat.send_message(UserMessage(text=prompt))).strip()
        # clean
        resp = resp.split("\\n")[0].strip().strip("\\".,")
        if resp in names:
            return {"assignee": resp}
        # case-insensitive match
        low = {n.lower(): n for n in names}
        if resp.lower() in low:
            return {"assignee": low[resp.lower()]}
        return {"assignee": ""}
    except Exception:
        logging.exception("assign error")
        return {"assignee": ""}'''

NEW_ASSIGN = '''    try:
        resp = await _gemini_text(prompt, system)
        resp = resp.split("\\n")[0].strip().strip("\\".,")
        if resp in names:
            return {"assignee": resp}
        low = {n.lower(): n for n in names}
        if resp.lower() in low:
            return {"assignee": low[resp.lower()]}
        return {"assignee": ""}
    except Exception:
        logging.exception("assign error")
        return {"assignee": ""}'''

patched = patched.replace(OLD_ASSIGN, NEW_ASSIGN, 1)

# ── 6. Patch VISION EXTRACT ───────────────────────────────────────────────────
OLD_VISION = '''    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage, ImageContent
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"vision_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        msg = UserMessage(text=prompt, file_contents=[ImageContent(image_base64=img)])
        resp_text = str(await chat.send_message(msg)).strip()'''

NEW_VISION = '''    try:
        resp_text = await _gemini_vision(prompt, img, system)'''

patched = patched.replace(OLD_VISION, NEW_VISION, 1)

# ── 7. Patch WEEKLY BRIEF ─────────────────────────────────────────────────────
OLD_BRIEF = '''    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"brief_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        response = await chat.send_message(UserMessage(text=prompt))
        brief_text = str(response).strip()'''

NEW_BRIEF = '''    try:
        brief_text = await _gemini_text(prompt, system)'''

patched = patched.replace(OLD_BRIEF, NEW_BRIEF, 1)

# ── 8. Patch VOICE TRANSCRIBE (Whisper → Gemini audio) ───────────────────────
OLD_VOICE_STT = '''    try:
        from emergentintegrations.llm.openai import OpenAISpeechToText
        stt = OpenAISpeechToText(api_key=EMERGENT_LLM_KEY)
        bio = io.BytesIO(raw)
        bio.name = f"voice.{ext}"
        resp = await stt.transcribe(
            file=bio,
            model="whisper-1",
            response_format="json",
        )
        transcript = (resp.text if hasattr(resp, "text") else str(resp)).strip()
    except Exception:
        logging.exception("STT error")
        raise HTTPException(status_code=500, detail="Transcription failed")'''

NEW_VOICE_STT = '''    try:
        transcript = await _gemini_audio(raw, ext)
    except Exception:
        logging.exception("STT error")
        raise HTTPException(status_code=500, detail="Transcription failed")'''

patched = patched.replace(OLD_VOICE_STT, NEW_VOICE_STT, 1)

# ── 9. Patch VOICE CLASSIFY ───────────────────────────────────────────────────
OLD_VOICE_CLASSIFY = '''    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"voice_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=classify_system,
        ).with_model("gemini", "gemini-3-flash-preview")
        resp_text = str(await chat.send_message(UserMessage(text=classify_prompt))).strip()'''

NEW_VOICE_CLASSIFY = '''    try:
        resp_text = await _gemini_text(classify_prompt, classify_system)'''

patched = patched.replace(OLD_VOICE_CLASSIFY, NEW_VOICE_CLASSIFY, 1)

# ── 10. Patch CONCIERGE CHAT ──────────────────────────────────────────────────
OLD_CONCIERGE = '''    reply = "Sorry, I couldn\'t think of anything useful right now. Try again?"
    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"concierge_{user.family_id}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        # Pass last few turns for context (simplified — just send the new user message; the session_id
        # keeps server-side history light on the LLM side per session)
        # Include recent turns manually to give context:
        convo_context = ""
        if len(history) > 1:
            recent = history[-8:-1]  # last 7 turns before this one
            for h in recent:
                prefix = "Parent" if h["role"] == "user" else "You"
                convo_context += f"\\n{prefix}: {h[\'text\']}"
        prompt = f"{convo_context}\\nParent: {text}\\nYou:" if convo_context else text
        resp = await chat.send_message(UserMessage(text=prompt))
        reply = str(resp).strip() or reply
    except Exception:
        logging.exception("Concierge error")'''

NEW_CONCIERGE = '''    reply = "Sorry, I couldn\'t think of anything useful right now. Try again?"
    try:
        convo_context = ""
        if len(history) > 1:
            recent = history[-8:-1]
            for h in recent:
                prefix = "Parent" if h["role"] == "user" else "You"
                convo_context += f"\\n{prefix}: {h[\'text\']}"
        prompt = f"{convo_context}\\nParent: {text}\\nYou:" if convo_context else text
        reply = await _gemini_text(prompt, system) or reply
    except Exception:
        logging.exception("Concierge error")'''

patched = patched.replace(OLD_CONCIERGE, NEW_CONCIERGE, 1)

# ── Verify no emergentintegrations left ───────────────────────────────────────
remaining = [i+1 for i, l in enumerate(patched.splitlines()) if "emergentintegrations" in l]
if remaining:
    print(f"WARNING: emergentintegrations still found on lines: {remaining}")
else:
    print("✅ All emergentintegrations references removed")

# ── Write patched file ────────────────────────────────────────────────────────
SERVER.write_text(patched, encoding="utf-8")
print("✅ backend/server.py patched successfully")
print()
print("Next steps:")
print("  1. Update backend/requirements.txt (see instructions)")
print("  2. Add GOOGLE_API_KEY to Railway environment variables")
print("  3. git add backend/server.py backend/requirements.txt")
print("  4. git commit -m 'Replace emergentintegrations with google-generativeai'")
print("  5. git push")
