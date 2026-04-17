from fastapi import FastAPI, APIRouter, HTTPException, Request, Response, Depends, UploadFile, File
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import io
import json as json_lib
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
RESEND_API_KEY = os.environ.get('RESEND_API_KEY', '')
RESEND_FROM_EMAIL = os.environ.get('RESEND_FROM_EMAIL', 'onboarding@resend.dev')
PUBLIC_APP_URL = os.environ.get('PUBLIC_APP_URL', 'https://ai-household.preview.emergentagent.com')

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
    recurrence: Literal["none", "daily", "weekly", "monthly"] = "none"
    reminder_minutes: int = 0  # 0 = no reminder; else minutes before due_date
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
    recurrence: Literal["none", "daily", "weekly", "monthly"] = "none"
    reminder_minutes: int = 0


class CardUpdate(BaseModel):
    status: Optional[Literal["OPEN", "DONE"]] = None


class FamilyMember(BaseModel):
    member_id: str
    family_id: str
    name: str
    role: str  # "Parent", "Child"
    avatar: Optional[str] = None
    stars: int = 0


class Reward(BaseModel):
    reward_id: str
    family_id: str
    title: str
    cost_stars: int
    icon: Optional[str] = None
    created_at: datetime


class RewardCreate(BaseModel):
    title: str
    cost_stars: int
    icon: Optional[str] = None


class VisionInput(BaseModel):
    image_base64: str  # data:image/jpeg;base64,... or raw base64


class InviteCreate(BaseModel):
    email: str


class InvitePublic(BaseModel):
    token: str
    family_id: str
    inviter_name: str
    inviter_email: str
    email: str
    used: bool


class InviteAcceptParams(BaseModel):
    session_id: str
    invite_token: Optional[str] = None


class VisionDraft(BaseModel):
    type: Literal["SIGN_SLIP", "RSVP", "TASK"]
    title: str
    description: str = ""
    assignee: str = ""
    due_date: Optional[str] = None


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
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": "Emma", "role": "Child", "avatar": None, "stars": 0},
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": "Liam", "role": "Child", "avatar": None, "stars": 0},
        {"member_id": str(uuid.uuid4()), "family_id": family_id, "name": user_name, "role": "Parent", "avatar": None, "stars": 0},
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
    """Exchange Emergent Auth session_id for a persistent session. Accepts optional invite_token."""
    body = await request.json()
    session_id = body.get("session_id")
    invite_token = body.get("invite_token")
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

    # Resolve invite (if any) to target family
    invited_family_id = None
    invite_doc = None
    if invite_token:
        invite_doc = await db.invites.find_one({"token": invite_token, "used_at": None}, {"_id": 0})
        if invite_doc:
            invited_family_id = invite_doc["family_id"]

    # Upsert user
    existing_user = await db.users.find_one({"email": email}, {"_id": 0})
    if existing_user:
        user_id = existing_user["user_id"]
        family_id = existing_user["family_id"]
        await db.users.update_one(
            {"user_id": user_id},
            {"$set": {"name": name, "picture": picture}}
        )
        # If existing user accepts invite, we don't silently move them — ignore for safety
    else:
        user_id = f"user_{uuid.uuid4().hex[:12]}"
        if invited_family_id:
            family_id = invited_family_id
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
            # Add them as a Parent member in the existing family (don't seed new data)
            await db.family_members.insert_one({
                "member_id": str(uuid.uuid4()),
                "family_id": family_id,
                "name": name,
                "role": "Parent",
                "avatar": picture,
                "stars": 0,
            })
            # Mark invite used
            await db.invites.update_one(
                {"token": invite_token},
                {"$set": {"used_at": datetime.now(timezone.utc), "accepted_by_user_id": user_id}},
            )
        else:
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


@api_router.post("/family/invite")
async def create_family_invite(payload: InviteCreate, user: User = Depends(get_current_user)):
    """Create an invite and email the join link via Resend."""
    email = (payload.email or "").strip().lower()
    if "@" not in email or "." not in email:
        raise HTTPException(status_code=400, detail="Valid email required")

    token = uuid.uuid4().hex
    invite = {
        "token": token,
        "family_id": user.family_id,
        "inviter_user_id": user.user_id,
        "inviter_name": user.name,
        "inviter_email": user.email,
        "email": email,
        "created_at": datetime.now(timezone.utc),
        "used_at": None,
        "accepted_by_user_id": None,
    }
    await db.invites.insert_one(invite)

    join_url = f"{PUBLIC_APP_URL}/?invite={token}"
    sent = False
    err_detail = None

    if RESEND_API_KEY:
        subject = f"{user.name} invited you to their Household COO"
        html = f"""
<!doctype html>
<html><body style="margin:0;padding:0;background:#080910;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#080910;padding:40px 20px;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0" style="background:#111218;border:1px solid rgba(255,255,255,0.08);border-radius:24px;padding:40px;">
        <tr><td>
          <p style="margin:0 0 8px 0;color:#6366F1;font-size:12px;letter-spacing:2px;text-transform:uppercase;">Household COO</p>
          <h1 style="margin:0 0 18px 0;color:#ffffff;font-size:30px;font-weight:400;font-style:italic;font-family:Georgia,'Times New Roman',serif;line-height:36px;">
            {user.name} wants you on the family team.
          </h1>
          <p style="margin:0 0 28px 0;color:rgba(255,255,255,0.7);font-size:15px;line-height:24px;">
            Join <strong style="color:#fff;">{user.name}</strong>'s Household COO — a shared command center for school flyers,
            RSVPs, permission slips, and everything else that used to pile up.
          </p>
          <a href="{join_url}" style="display:inline-block;background:#ffffff;color:#080910;padding:14px 26px;border-radius:9999px;text-decoration:none;font-weight:600;font-size:15px;">
            Accept invitation →
          </a>
          <p style="margin:28px 0 0 0;color:rgba(255,255,255,0.35);font-size:11px;line-height:18px;">
            Or paste this link: <a href="{join_url}" style="color:rgba(255,255,255,0.5);">{join_url}</a>
          </p>
        </td></tr>
      </table>
      <p style="margin:20px 0 0 0;color:rgba(255,255,255,0.3);font-size:11px;">
        Sent from Household COO. If this wasn't you, ignore this email.
      </p>
    </td></tr>
  </table>
</body></html>
"""
        try:
            async with httpx.AsyncClient() as http_client:
                r = await http_client.post(
                    "https://api.resend.com/emails",
                    headers={
                        "Authorization": f"Bearer {RESEND_API_KEY}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "from": f"Household COO <{RESEND_FROM_EMAIL}>",
                        "to": [email],
                        "subject": subject,
                        "html": html,
                    },
                    timeout=15.0,
                )
                sent = r.status_code in (200, 202)
                if not sent:
                    err_detail = f"Resend {r.status_code}: {r.text[:200]}"
        except Exception as e:
            err_detail = str(e)
            logging.exception("Resend error")
    else:
        err_detail = "RESEND_API_KEY not configured"

    return {"ok": True, "sent": sent, "token": token, "join_url": join_url, "error": err_detail}


@api_router.get("/family/invite/{token}", response_model=InvitePublic)
async def get_invite(token: str):
    """Public endpoint — landing page uses this to show 'X invited you to their family'."""
    doc = await db.invites.find_one({"token": token}, {"_id": 0})
    if not doc:
        raise HTTPException(status_code=404, detail="Invite not found")
    return InvitePublic(
        token=doc["token"],
        family_id=doc["family_id"],
        inviter_name=doc["inviter_name"],
        inviter_email=doc["inviter_email"],
        email=doc["email"],
        used=doc.get("used_at") is not None,
    )


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


def _next_due_date(due_date_iso: Optional[str], recurrence: str) -> Optional[str]:
    if not due_date_iso or recurrence == "none":
        return None
    try:
        dt = datetime.fromisoformat(due_date_iso.replace("Z", "+00:00"))
    except Exception:
        return None
    if recurrence == "daily":
        dt = dt + timedelta(days=1)
    elif recurrence == "weekly":
        dt = dt + timedelta(days=7)
    elif recurrence == "monthly":
        dt = dt + timedelta(days=30)
    return dt.isoformat()


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
        recurrence=payload.recurrence,
        reminder_minutes=payload.reminder_minutes,
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

    # If recurring & marked DONE, spawn next instance
    if payload.status == "DONE" and card_doc.get("recurrence", "none") != "none":
        next_due = _next_due_date(card_doc.get("due_date"), card_doc["recurrence"])
        if next_due:
            next_card = {
                "card_id": str(uuid.uuid4()),
                "family_id": card_doc["family_id"],
                "type": card_doc["type"],
                "title": card_doc["title"],
                "description": card_doc.get("description", ""),
                "assignee": card_doc.get("assignee", ""),
                "due_date": next_due,
                "status": "OPEN",
                "source": card_doc.get("source", "MANUAL"),
                "image_base64": card_doc.get("image_base64"),
                "recurrence": card_doc["recurrence"],
                "reminder_minutes": card_doc.get("reminder_minutes", 0),
                "created_at": datetime.now(timezone.utc),
                "completed_at": None,
            }
            await db.cards.insert_one(next_card)

    # Award stars if task is done by a Child assignee
    stars_awarded = 0
    if payload.status == "DONE" and card_doc["type"] == "TASK":
        assignee_name = (card_doc.get("assignee") or "").strip()
        if assignee_name:
            member = await db.family_members.find_one(
                {"family_id": user.family_id, "name": assignee_name, "role": "Child"},
                {"_id": 0},
            )
            if member:
                stars_awarded = 5
                await db.family_members.update_one(
                    {"member_id": member["member_id"]},
                    {"$inc": {"stars": stars_awarded}},
                )

    updated = await db.cards.find_one({"card_id": card_id}, {"_id": 0})
    result = Card(**updated).dict()
    # Note: stars_awarded returned via separate call (GET /family/members); keep response model stable
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
@api_router.post("/vision/extract", response_model=VisionDraft)
async def vision_extract(payload: VisionInput, user: User = Depends(get_current_user)):
    """Send image (flyer/note) to Gemini vision → structured Smart Card draft."""
    img = payload.image_base64 or ""
    if not img.startswith("data:"):
        img = f"data:image/jpeg;base64,{img}"

    members_docs = await db.family_members.find({"family_id": user.family_id}, {"_id": 0}).to_list(50)
    member_names = [m["name"] for m in members_docs]

    system = (
        "You extract a structured household task from a photo of a school flyer, note, invitation, or list. "
        "Respond ONLY with a JSON object: "
        "type (SIGN_SLIP | RSVP | TASK), title (max 80), description (max 200), "
        "assignee (one name from family list or empty), due_date (ISO date string if a date is visible, else null). "
        "Rules: SIGN_SLIP = permission slip / release form. RSVP = invitation/party. TASK = everything else. "
        "Return JSON only, no markdown fences."
    )
    prompt = (
        f"Family members: {', '.join(member_names) if member_names else 'none'}. "
        "Extract the key action from the attached image."
    )

    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage, ImageContent
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"vision_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=system,
        ).with_model("gemini", "gemini-3-flash-preview")
        msg = UserMessage(text=prompt, file_contents=[ImageContent(image_base64=img)])
        resp_text = str(await chat.send_message(msg)).strip()
        if resp_text.startswith("```"):
            resp_text = resp_text.strip("`")
            if resp_text.lower().startswith("json"):
                resp_text = resp_text[4:].strip()
        data = json_lib.loads(resp_text)
        t = (data.get("type") or "TASK").upper()
        if t not in ("SIGN_SLIP", "RSVP", "TASK"):
            t = "TASK"
        return VisionDraft(
            type=t,
            title=(data.get("title") or "New item")[:80],
            description=(data.get("description") or "")[:200],
            assignee=(data.get("assignee") or "").strip(),
            due_date=data.get("due_date"),
        )
    except Exception:
        logging.exception("Vision error")
        raise HTTPException(status_code=500, detail="Vision extraction failed")


@api_router.get("/cards/conflicts", response_model=List[Card])
async def card_conflicts(
    due_date: str,
    exclude_id: Optional[str] = None,
    user: User = Depends(get_current_user),
):
    """Return OPEN cards whose due_date is within ±2h of the given ISO datetime."""
    try:
        target = datetime.fromisoformat(due_date.replace("Z", "+00:00"))
        if target.tzinfo is None:
            target = target.replace(tzinfo=timezone.utc)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid due_date")

    docs = await db.cards.find(
        {"family_id": user.family_id, "status": "OPEN", "due_date": {"$ne": None}},
        {"_id": 0},
    ).to_list(500)
    conflicts = []
    for d in docs:
        if exclude_id and d["card_id"] == exclude_id:
            continue
        try:
            dd = datetime.fromisoformat(str(d["due_date"]).replace("Z", "+00:00"))
            if dd.tzinfo is None:
                dd = dd.replace(tzinfo=timezone.utc)
            delta = abs((dd - target).total_seconds())
            if delta <= 2 * 3600:
                conflicts.append(Card(**d))
        except Exception:
            continue
    return conflicts


# ============================================================
# REWARDS
# ============================================================
@api_router.get("/rewards", response_model=List[Reward])
async def list_rewards(user: User = Depends(get_current_user)):
    docs = await db.rewards.find({"family_id": user.family_id}, {"_id": 0}).sort("cost_stars", 1).to_list(100)
    return [Reward(**d) for d in docs]


@api_router.post("/rewards", response_model=Reward)
async def create_reward(payload: RewardCreate, user: User = Depends(get_current_user)):
    r = Reward(
        reward_id=str(uuid.uuid4()),
        family_id=user.family_id,
        title=payload.title,
        cost_stars=max(1, int(payload.cost_stars)),
        icon=payload.icon,
        created_at=datetime.now(timezone.utc),
    )
    await db.rewards.insert_one(r.dict())
    return r


@api_router.delete("/rewards/{reward_id}")
async def delete_reward(reward_id: str, user: User = Depends(get_current_user)):
    res = await db.rewards.delete_one({"reward_id": reward_id, "family_id": user.family_id})
    if res.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Reward not found")
    return {"ok": True}


class RedeemPayload(BaseModel):
    member_id: str


@api_router.post("/rewards/{reward_id}/redeem")
async def redeem_reward(reward_id: str, payload: RedeemPayload, user: User = Depends(get_current_user)):
    reward = await db.rewards.find_one({"reward_id": reward_id, "family_id": user.family_id}, {"_id": 0})
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
    member = await db.family_members.find_one(
        {"member_id": payload.member_id, "family_id": user.family_id}, {"_id": 0}
    )
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    current = int(member.get("stars", 0))
    if current < reward["cost_stars"]:
        raise HTTPException(status_code=400, detail="Not enough stars")
    await db.family_members.update_one(
        {"member_id": payload.member_id},
        {"$inc": {"stars": -reward["cost_stars"]}},
    )
    await db.reward_redemptions.insert_one({
        "redemption_id": str(uuid.uuid4()),
        "family_id": user.family_id,
        "member_id": payload.member_id,
        "reward_id": reward_id,
        "title": reward["title"],
        "cost_stars": reward["cost_stars"],
        "redeemed_at": datetime.now(timezone.utc),
    })
    updated = await db.family_members.find_one({"member_id": payload.member_id}, {"_id": 0})
    return {"ok": True, "member": FamilyMember(**updated).dict()}


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
# VOICE → STT → CLASSIFY (Whisper + Gemini)
# ============================================================
class VoiceDraft(BaseModel):
    transcript: str
    type: Literal["SIGN_SLIP", "RSVP", "TASK"]
    title: str
    description: str = ""
    assignee: str = ""


@api_router.post("/voice/transcribe", response_model=VoiceDraft)
async def voice_transcribe(
    audio: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    """Receive audio blob → Whisper-1 transcription → Gemini classifier → card draft"""
    raw = await audio.read()
    if len(raw) == 0:
        raise HTTPException(status_code=400, detail="Empty audio")
    if len(raw) > 24 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Audio too large (max 24MB)")

    # Determine extension from content type
    ct = (audio.content_type or "").lower()
    ext = "webm"
    if "mp4" in ct or "m4a" in ct:
        ext = "m4a"
    elif "mpeg" in ct or "mp3" in ct:
        ext = "mp3"
    elif "wav" in ct:
        ext = "wav"
    elif "ogg" in ct:
        ext = "ogg"

    try:
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
        raise HTTPException(status_code=500, detail="Transcription failed")

    if not transcript:
        raise HTTPException(status_code=400, detail="No speech detected")

    # Classify with Gemini into structured card
    members_docs = await db.family_members.find({"family_id": user.family_id}, {"_id": 0}).to_list(50)
    member_names = [m["name"] for m in members_docs]

    classify_system = (
        "You extract a structured household task from a parent's spoken note. "
        "Respond ONLY with a compact JSON object with keys: "
        "type (one of SIGN_SLIP, RSVP, TASK), title (short, max 80 chars), "
        "description (optional context, max 200 chars), assignee (one name from the family list or empty string). "
        "Rules: SIGN_SLIP = school permission/release forms. RSVP = party/event invitations. TASK = everything else. "
        "No prose. No markdown. JSON only."
    )
    classify_prompt = (
        f"Family members: {', '.join(member_names) if member_names else 'none'}.\n"
        f"Spoken note: \"{transcript}\"\n\n"
        "Return JSON now."
    )

    parsed = {
        "type": "TASK",
        "title": transcript[:80],
        "description": "",
        "assignee": "",
    }
    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
        chat = LlmChat(
            api_key=EMERGENT_LLM_KEY,
            session_id=f"voice_{user.user_id}_{uuid.uuid4().hex[:8]}",
            system_message=classify_system,
        ).with_model("gemini", "gemini-3-flash-preview")
        resp_text = str(await chat.send_message(UserMessage(text=classify_prompt))).strip()
        # Strip code fences if any
        if resp_text.startswith("```"):
            resp_text = resp_text.strip("`")
            if resp_text.lower().startswith("json"):
                resp_text = resp_text[4:].strip()
        data = json_lib.loads(resp_text)
        t = (data.get("type") or "TASK").upper()
        if t not in ("SIGN_SLIP", "RSVP", "TASK"):
            t = "TASK"
        parsed = {
            "type": t,
            "title": (data.get("title") or transcript)[:80],
            "description": (data.get("description") or "")[:200],
            "assignee": (data.get("assignee") or "").strip(),
        }
    except Exception:
        logging.exception("Classify error; falling back to raw transcript")

    return VoiceDraft(transcript=transcript, **parsed)


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
