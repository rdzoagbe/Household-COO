"""
Backend API tests for Household COO — focus on bonus features + regression.
Uses the live backend URL from /app/frontend/.env (EXPO_PUBLIC_BACKEND_URL) and the
seeded session token from /app/memory/test_credentials.md.
"""
import os
import sys
import json
import time
import requests
from pathlib import Path


def load_backend_url() -> str:
    env_path = Path("/app/frontend/.env")
    for line in env_path.read_text().splitlines():
        if line.startswith("EXPO_PUBLIC_BACKEND_URL"):
            return line.split("=", 1)[1].strip().strip('"').rstrip("/")
    raise RuntimeError("EXPO_PUBLIC_BACKEND_URL not found")


BASE = load_backend_url() + "/api"
TOKEN = "test_session_1776435744337"
HEADERS = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}

results = []  # list of (name, ok, detail)


def record(name, ok, detail=""):
    mark = "PASS" if ok else "FAIL"
    print(f"[{mark}] {name} :: {detail}")
    results.append((name, ok, detail))


def req(method, path, **kwargs):
    url = f"{BASE}{path}"
    kwargs.setdefault("timeout", 45)
    kwargs.setdefault("headers", HEADERS)
    return requests.request(method, url, **kwargs)


def test_auth_me():
    r = req("GET", "/auth/me")
    ok = r.status_code == 200 and "@example.com" in (r.json().get("email") or "")
    record("GET /auth/me", ok, f"status={r.status_code} body={r.text[:200]}")
    return r.json() if r.ok else None


def test_family_members_has_pin():
    r = req("GET", "/family/members")
    if r.status_code != 200:
        record("GET /family/members", False, f"status={r.status_code}")
        return None
    members = r.json()
    ok = isinstance(members, list) and len(members) == 3
    all_have_flag = all(isinstance(m.get("has_pin"), bool) for m in members)
    ok = ok and all_have_flag
    emma = next((m for m in members if m["name"] == "Emma"), None)
    detail = f"count={len(members)} has_pin_flag_on_all={all_have_flag} emma_present={emma is not None}"
    record("GET /family/members returns has_pin + 3 members", ok and emma is not None, detail)
    return emma


def test_pin_flow(emma_id: str):
    # 2) set PIN 1234
    r = req("PUT", f"/family/members/{emma_id}/pin", data=json.dumps({"pin": "1234"}))
    ok = r.status_code == 200 and r.json() == {"ok": True, "has_pin": True}
    record("PUT /family/members/{id}/pin (1234)", ok, f"status={r.status_code} body={r.text[:200]}")

    # 3) verify correct
    r = req("POST", f"/family/members/{emma_id}/verify-pin", data=json.dumps({"pin": "1234"}))
    ok = r.status_code == 200 and r.json().get("ok") is True
    record("POST verify-pin (correct 1234)", ok, f"status={r.status_code} body={r.text[:200]}")

    # 4) verify wrong => 401
    r = req("POST", f"/family/members/{emma_id}/verify-pin", data=json.dumps({"pin": "0000"}))
    ok = r.status_code == 401
    record("POST verify-pin (wrong 0000) -> 401", ok, f"status={r.status_code} body={r.text[:200]}")

    # 5) clear PIN with empty string
    r = req("PUT", f"/family/members/{emma_id}/pin", data=json.dumps({"pin": ""}))
    ok = r.status_code == 200 and r.json() == {"ok": True, "has_pin": False}
    record("PUT pin '' clears", ok, f"status={r.status_code} body={r.text[:200]}")

    # confirm via GET /family/members Emma.has_pin == false
    r = req("GET", "/family/members")
    emma = next((m for m in r.json() if m["name"] == "Emma"), None) if r.ok else None
    ok = emma is not None and emma.get("has_pin") is False
    record("After clear, GET members shows Emma.has_pin=false", ok, f"emma={emma}")

    # 6) invalid length -> 400
    r = req("PUT", f"/family/members/{emma_id}/pin", data=json.dumps({"pin": "12"}))
    ok = r.status_code == 400
    record("PUT pin '12' -> 400 invalid length", ok, f"status={r.status_code} body={r.text[:200]}")


def test_ai_assign():
    body = {
        "title": "Pickup Emma from soccer",
        "description": "drop off at 5pm",
        "type": "TASK",
    }
    r = req("POST", "/ai/assign", data=json.dumps(body))
    if r.status_code != 200:
        record("POST /ai/assign", False, f"status={r.status_code} body={r.text[:300]}")
        return
    data = r.json()
    ok = isinstance(data, dict) and "assignee" in data and isinstance(data["assignee"], str)
    record("POST /ai/assign returns {assignee:str}, no 5xx", ok,
           f"status={r.status_code} assignee={data.get('assignee')!r}")


def test_cards_crud():
    r = req("GET", "/cards")
    ok = r.status_code == 200 and isinstance(r.json(), list)
    record("GET /cards", ok, f"status={r.status_code} len={len(r.json()) if r.ok else 'n/a'}")

    payload = {
        "type": "TASK",
        "title": "Test card from backend test",
        "source": "MANUAL",
    }
    r = req("POST", "/cards", data=json.dumps(payload))
    if r.status_code != 200:
        record("POST /cards", False, f"status={r.status_code} body={r.text[:300]}")
        return
    card = r.json()
    card_id = card.get("card_id")
    record("POST /cards", bool(card_id), f"card_id={card_id}")

    # PATCH
    r = req("PATCH", f"/cards/{card_id}", data=json.dumps({"status": "DONE"}))
    ok = r.status_code == 200 and r.json().get("status") == "DONE"
    record("PATCH /cards/{id} status=DONE", ok, f"status={r.status_code}")

    # DELETE
    r = req("DELETE", f"/cards/{card_id}")
    ok = r.status_code in (200, 204)
    record("DELETE /cards/{id}", ok, f"status={r.status_code} body={r.text[:100]}")


def test_rewards_vault():
    r = req("GET", "/rewards")
    record("GET /rewards", r.status_code == 200 and isinstance(r.json(), list),
           f"status={r.status_code}")
    r = req("GET", "/vault")
    record("GET /vault", r.status_code == 200 and isinstance(r.json(), list),
           f"status={r.status_code}")


def test_brief_weekly():
    t = time.time()
    r = req("POST", "/brief/weekly", timeout=45)
    dt = time.time() - t
    if r.status_code != 200:
        record("POST /brief/weekly", False, f"status={r.status_code} took={dt:.1f}s body={r.text[:300]}")
        return
    data = r.json()
    ok = isinstance(data.get("brief"), str) and bool(data.get("brief")) and data.get("generated_at")
    record("POST /brief/weekly", ok, f"status=200 took={dt:.1f}s brief_len={len(data.get('brief',''))}")


def main():
    print(f"Base URL: {BASE}")

    me = test_auth_me()
    if me is None:
        print("Auth failed — aborting")
        sys.exit(1)

    emma = test_family_members_has_pin()
    if not emma:
        print("Cannot find Emma — aborting PIN tests")
    else:
        test_pin_flow(emma["member_id"])

    test_ai_assign()
    test_cards_crud()
    test_rewards_vault()
    test_brief_weekly()

    print("\n===== SUMMARY =====")
    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print(f"{passed}/{total} passed")
    for name, ok, detail in results:
        print(f"  {'OK  ' if ok else 'FAIL'}  {name}")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
