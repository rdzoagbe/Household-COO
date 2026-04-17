from fastapi import FastAPI, APIRouter, HTTPException, Request, Response, Depends
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
import uuid
import httpx
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional, Literal
from datetime import datetime, timedelta, timezone


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

EMERGENT_LLM_KEY = os.environ.get('EMERGENT_LLM_KEY', '')

app = FastAPI()
api_router = APIRouter(prefix="/api")


# ============================================================
# MODELS
# ============================================================
class User(BaseModel):
    user_id: str
    email: str
    name: str
    picture: Optional[str] = None
    family_id: str
    language: str = "en"
    created_at: datetime


class UserPublic(BaseModel):
    user_id: str
    email: str
    name: str
    picture: Optional[str] = None
    family_id: str
    language: str = "en"


class Card(BaseModel):
    card_id: str
    family_id: str
    type: Literal["SIGN_SLIP", "RSVP", "TASK"]
    title: str
    description: Optional[str] = ""
    assignee: Optional[str] = ""  # family member name
    due_date: Optional[str] = None  # ISO date string
    status: Literal["OPEN", "DONE"] = "OPEN"
    source: Literal["AI", "MANUAL", "VOICE", "CAMERA"] = "MANUAL"
    image_base64: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None


class CardCreate(BaseModel):
    type: Literal["SIGN_SLIP", "RSVP", "TASK"]
    title: str
    description: Optional[str] = ""
    assignee: Optional[str] = ""
    due_date: Optional[str] = None
    source: Literal["AI", "MANUAL", "VOICE", "CAMERA"] = "MANUAL"
    image_base64: Optional[str] = None


class CardUpdate(BaseModel):
    status: Optional[Literal["OPEN", "DONE"]] = None


class FamilyMember(BaseModel):
    member_id: str
    family_id: str
    name: str
    role: str  # "Parent", "Child"
    avatar: Optional[str] = None


class VaultDoc(BaseModel):
    doc_id: str
    family_id: str
    title: str
    category: str  # "Medical", "School", "Insurance", "Legal"
    image_base64: str
    created_at: datetime


class VaultDocCreate(BaseModel):
    title: str
    category: str
    image_base64: str


class LanguageUpdate(BaseModel):
    language: str


class BriefResponse(BaseModel):
    brief: str
    generated_at: datetime


# ============================================================
# AUTH HELPERS
# ============================================================
async def get_current_user(request: Request) -> User:
    session_token = request.cookies.get("session_token")
    if not session_token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            session_token = auth_header[7:]
    if not session_token:
        raise HTTPException(status_code=401, detail="Not authenticated")

    session_doc = await db.user_sessions.find_one({"session_token": session_token}, {"_id": 0})
    if not session_doc:
        raise HTTPException(status_code=401, detail="Invalid session")

    expires_at = session_doc["expires_at"]
    if isinstance(expires_at, str):
        expires_at = datetime.fromisoformat(expires_at)
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at < datetime.now(timezone.utc):
        raise HTTPException(status_code=401, detail="Session expired")

    user_doc = await db.users.find_one({"user_id": session_doc["user_id"]}, {"_id": 0})
    if not user_doc:
        raise HTTPException(status_code=401, detail="User not found")
    return User(**user_doc)


async def seed_family_data(family_id: str, user_name: str):
    """Seed sample family members and cards for a new family"""
    existing = await db.family_members.find_one({"family_id": family_id})
    if existing:
        return

    members = [
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": "Emma", "role": "Child", "avatar": None},
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": "Liam", "role": "Child", "avatar": None},
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": user_name, "role": "Parent", "avatar": None},
    ]
    await db.family_members.insert_many(members)

    now = datetime.now(timezone.utc)
    sample_cards = [
        {
            "card_id": str(uuid.uuid4()),
            "family_id": family_id,
            "type": "SIGN_SLIP",
            "title": "Field trip permission slip — Science Museum",
            "description": "Emma's 4th grade class needs signed permission by Friday.",
            "assignee": "Emma",
            "due_date": (now + timedelta(days=3)).isoformat(),
            "status": "OPEN",
            "source": "AI",
            "created_at": now,
            "completed_at": None,
        },
        {
            "card_id": str(uuid.uuid4()),
            "family_id": family_id,
            "type": "RSVP",
            "title": "Birthday party — Sofia turns 8",
            "description": "Saturday 2pm at Jumpville. Bring a gift under $25.",
            "assignee": "Liam",
            "due_date": (now + timedelta(days=5)).isoformat(),
            "status": "OPEN",
            "source": "AI",
            "created_at": now - timedelta(hours=3),
            "completed_at": None,
        },
        {
            "card_id": str(uuid.uuid4()),
            "family_id": family_id,
            "type": "TASK",
            "title": "Pick up groceries: milk, bread, eggs, berries",
            "description": "Low on essentials. Whole Foods run after school.",
            "assignee": user_name,
            "due_date": (now + timedelta(days=1)).isoformat(),
            "status": "OPEN",
            "source": "MANUAL",
            "created_at": now - timedelta(hours=6),
            "completed_at": None,
        },
        {
            "card_id": str(uuid.uuid4()),
            "family_id": family_id,
            "type": "TASK",
            "title": "Book dentist cleaning for Emma",
            "description": "6-month checkup is overdue. Dr. Patel's office.",
            "assignee": user_name,
            "due_date": (now + timedelta(days=7)).isoformat(),
            "status": "OPEN",
            "source": "VOICE",
            "created_at": now - timedelta(days=1),
            "completed_at": None,
        },
        {
            "card_id": str(uuid.uuid4()),
            "family_id": family_id,
            "type": "SIGN_SLIP",
            "title": "Media release form — Spring concert",
            "description": "Liam's choir concert will be filmed. Sign to opt-in.",
            "assignee": "Liam",
            "due_date": (now + timedelta(days=10)).isoformat(),
            "status": "OPEN",
            "source": "CAMERA",
            "created_at": now - timedelta(days=2),
            "completed_at": None,
        },
    ]
    await db.cards.insert_many(sample_cards)


# ============================================================
# AUTH ROUTES
# ============================================================
@api_router.post("/auth/session")
async def create_session(request: Request, response: Response):
    """Exchange Emergent Auth session_id for a persistent session"""
    body = await request.json()
    session_id = body.get("session_id")
    if not session_id:
        raise HTTPException(status_code=400, detail="session_id required")

    async with httpx.AsyncClient() as http_client:
        resp = await http_client.get(
            "https://demobackend.emergentagent.com/auth/v1/env/oauth/session-data",
            headers={"X-Session-ID": session_id},
            timeout=10.0,
        )
        if resp.status_code != 200:
            raise HTTPException(status_code=401, detail="Invalid session_id")
        data = resp.json()

    email = data["email"]
    name = data["name"]
    picture = data.get("picture")
    session_token = data["session_token"]

    # Upsert user
    existing_user = await db.users.find_one({"email": email}, {"_id": 0})
    if existing_user:
        user_id = existing_user["user_id"]
        family_id = existing_user["family_id"]
        await db.users.update_one(
            {"user_id": user_id},
            {"$set": {"name": name, "picture": picture}}
        )
    else:
        user_id = f"user_{uuid.uuid4().hex[:12]}"
        family_id = f"family_{uuid.uuid4().hex[:12]}"
        new_user = {
            "user_id": user_id,
            "email": email,
            "name": name,
            "picture": picture,
            "family_id": family_id,
            "language": "en",
            "created_at": datetime.now(timezone.utc),
        }
        await db.users.insert_one(new_user)
        await seed_family_data(family_id, name)

    # Store session
    await db.user_sessions.insert_one({
        "user_id": user_id,
        "session_token": session_token,
        "expires_at": datetime.now(timezone.utc) + timedelta(days=7),
        "created_at": datetime.now(timezone.utc),
    })

    # Set cookie
    response.set_cookie(
        key="session_token",
        value=session_token,
        max_age=7 * 24 * 60 * 60,
        httponly=True,
        secure=True,
        samesite="none",
        path="/",
    )

    user_doc = await db.users.find_one({"user_id": user_id}, {"_id": 0})
    return {"user": UserPublic(**user_doc).dict(), "session_token": session_token}


@api_router.get("/auth/me", response_model=UserPublic)
async def auth_me(user: User = Depends(get_current_user)):
    return UserPublic(**user.dict())


@api_router.post("/auth/logout")
async def logout(request: Request, response: Response):
    session_token = request.cookies.get("session_token")
    if not session_token:
        auth_header = request.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            session_token = auth_header[7:]
    if session_token:
        await db.user_sessions.delete_one({"session_token": session_token})
    response.delete_cookie("session_token", path="/", samesite="none", secure=True)
    return {"ok": True}


@api_router.patch("/auth/language")
async def update_language(payload: LanguageUpdate, user: User = Depends(get_current_user)):
    await db.users.update_one({"user_id": user.user_id}, {"$set": {"language": payload.language}})
    return {"ok": True, "language": payload.language}


# ============================================================
# FAMILY ROUTES
# ============================================================
@api_router.get("/family/members", response_model=List[FamilyMember])
async def get_family_members(user: User = Depends(get_current_user)):
    members = await db.family_members.find({"family_id": user.family_id}, {"_id": 0}).to_list(100)
    return [FamilyMember(**m) for m in members]


# ============================================================
# CARD / FEED ROUTES
# ============================================================
@api_router.get("/cards", response_model=List[Card])
async def list_cards(
    status: Optional[str] = None,
    user: User = Depends(get_current_user),
):
    query = {"family_id": user.family_id}
    if status:
        query["status"] = status
    cards = await db.cards.find(query, {"_id": 0}).sort("created_at", -1).to_list(500)
    return [Card(**c) for c in cards]


@api_router.post("/cards", response_model=Card)
async def create_card(payload: CardCreate, user: User = Depends(get_current_user)):
    card = Card(
        card_id=str(uuid.uuid4()),
        family_id=user.family_id,
        type=payload.type,
        title=payload.title,
        description=payload.description or "",
        assignee=payload.assignee or "",
        due_date=payload.due_date,
        status="OPEN",
        source=payload.source,
        image_base64=payload.image_base64,
        created_at=datetime.now(timezone.utc),
        completed_at=None,
    )
    await db.cards.insert_one(card.dict())
    return card


@api_router.patch("/cards/{card_id}", response_model=Card)
async def update_card(card_id: str, payload: CardUpdate, user: User = Depends(get_current_user)):
    card_doc = await db.cards.find_one({"card_id": card_id, "family_id": user.family_id}, {"_id": 0})
    if not card_doc:
        raise HTTPException(status_code=404, detail="Card not found")
    update: dict = {}
    if payload.status is not None:
        update["status"] = payload.status
        update["completed_at"] = datetime.now(timezone.utc) if payload.status == "DONE" else None
    if update:
        await db.cards.update_one({"card_id": card_id}, {"$set": update})
    updated = await db.cards.find_one({"card_id": card_id}, {"_id": 0})
    return Card(**updated)


@api_router.delete("/cards/{card_id}")
async def delete_card(card_id: str, user: User = Depends(get_current_user)):
    res = await db.cards.delete_one({"card_id": card_id, "family_id": user.family_id})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Card not found")
    return {"ok": True}


# ============================================================
# VAULT ROUTES
# ============================================================
@api_router.get("/vault", response_model=List[VaultDoc])
async def list_vault(user: User = Depends(get_current_user)):
    docs = await db.vault.find({"family_id": user.family_id}, {"_id": 0}).sort("created_at", -1).to_list(200)
    return [VaultDoc(**d) for d in docs]


@api_router.post("/vault", response_model=VaultDoc)
async def create_vault_doc(payload: VaultDocCreate, user: User = Depends(get_current_user)):
    doc = VaultDoc(
        doc_id=str(uuid.uuid4()),
        family_id=user.family_id,
        title=payload.title,
        category=payload.category,
        image_base64=payload.image_base64,
        created_at=datetime.now(timezone.utc),
    )
    await db.vault.insert_one(doc.dict())
    return doc


@api_router.delete("/vault/{doc_id}")
async def delete_vault_doc(doc_id: str, user: User = Depends(get_current_user)):
    res = await db.vault.delete_one({"doc_id": doc_id, "family_id": user.family_id})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Doc not found")
    return {"ok": True}


# ============================================================
# SUNDAY BRIEF (Gemini 3 Flash)
# ============================================================
@api_router.post("/brief/weekly", response_model=BriefResponse)
async def weekly_brief(user: User = Depends(get_current_user)):
    cards = await db.cards.find({"family_id": user.family_id}, {"_id": 0}).to_list(500)
    if not cards:
        return BriefResponse(
            brief="Your family feed is clear. A rare moment of stillness — savor it.",
            generated_at=datetime.now(timezone.utc),
        )

    # Build context
    open_items = [c for c in cards if c["status"] == "OPEN"]
    done_items = [c for c in cards if c["status"] == "DONE"]

    context_lines = []
    for c in open_items[:30]:
        due = c.get("due_date", "no due date")
        context_lines.append(
            f"- [{c['type']}] {c['title']} | assignee: {c.get('assignee') or 'unassigned'} | due: {due}"
        )

    context_block = "\n".join(context_lines) if context_lines else "No open items."
    done_count = len(done_items)
    open_count = len(open_items)

    system = (
        "You are the Chief of Staff for a busy family. Your job is to write an elegant, "
        "warm, and actionable Sunday Brief that helps parents see the week ahead clearly. "
        "Use short paragraphs, no bullet points, and a confident, reassuring tone. "
        "Reference specific items by name. End with one sentence of encouragement. "
        "Keep under 180 words."
    )
    prompt = (
        f"Family: {user.name}'s household.\n"
        f"Completed this week: {done_count} items.\n"
        f"Open items ({open_count}):\n{context_block}\n\n"
        "Write the Sunday Brief now."
    )

    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"brief_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        response = await chat.send_message(UserMessage(text=prompt))
        brief_text = str(response).strip()
    except Exception:
        logging.exception("LLM error")
        brief_text = (
            f"This week, your family has {open_count} open items and you've already closed {done_count}. "
            "Prioritize the signed permission slips first — those have hard deadlines tied to school. "
            "The RSVPs can be batched on one evening. "
            "You're steering a tight ship. Keep going."
        )

    return BriefResponse(brief=brief_text, generated_at=datetime.now(timezone.utc))


# ============================================================
# HEALTHCHECK
# ============================================================
@api_router.get("/")
async def root():
    return {"message": "Household COO API", "status": "ok"}


app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
