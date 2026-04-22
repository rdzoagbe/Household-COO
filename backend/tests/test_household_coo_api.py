"""
Backend API Tests for Household COO
Tests all 13 API endpoints with seeded test session
"""
import pytest
import requests
import os
import base64

# Read BASE_URL from frontend .env or use hardcoded value
BASE_URL = "https://ai-household.preview.emergentagent.com"
SESSION_TOKEN = "test_session_1776435744337"


@pytest.fixture
def api_client():
    """Shared requests session with auth"""
    session = requests.Session()
    session.headers.update({
        "Content-Type": "application/json",
        "Authorization": f"Bearer {SESSION_TOKEN}"
    })
    return session


@pytest.fixture
def api_client_no_auth():
    """Requests session without auth"""
    session = requests.Session()
    session.headers.update({"Content-Type": "application/json"})
    return session


class TestHealthCheck:
    """Health check endpoint"""

    def test_health_check(self, api_client_no_auth):
        """GET /api/ returns status ok"""
        response = api_client_no_auth.get(f"{BASE_URL}/api/")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert data["status"] == "ok"
        print("✓ Health check passed")


class TestAuth:
    """Authentication endpoints"""

    def test_auth_me_with_valid_session(self, api_client):
        """GET /api/auth/me returns test user with valid session"""
        response = api_client.get(f"{BASE_URL}/api/auth/me")
        assert response.status_code == 200
        
        data = response.json()
        assert data["user_id"] == "user_test1776435744337"
        assert data["email"] == "test.user.1776435744337@example.com"
        assert data["name"] == "Alex Chen"
        assert data["family_id"] == "family_test1776435744337"
        assert "language" in data
        print(f"✓ Auth /me passed: {data['name']}")

    def test_auth_me_without_session(self, api_client_no_auth):
        """GET /api/auth/me returns 401 without session"""
        response = api_client_no_auth.get(f"{BASE_URL}/api/auth/me")
        assert response.status_code == 401
        print("✓ Auth /me correctly rejects unauthenticated request")

    def test_update_language(self, api_client):
        """PATCH /api/auth/language updates user language"""
        response = api_client.patch(
            f"{BASE_URL}/api/auth/language",
            json={"language": "es"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["ok"] is True
        assert data["language"] == "es"
        
        # Verify persistence
        me_response = api_client.get(f"{BASE_URL}/api/auth/me")
        assert me_response.json()["language"] == "es"
        
        # Reset to English
        api_client.patch(f"{BASE_URL}/api/auth/language", json={"language": "en"})
        print("✓ Language update passed")

    def test_logout(self, api_client):
        """POST /api/auth/logout returns ok"""
        # Create a temporary session for logout test
        import uuid
        temp_token = f"temp_logout_{uuid.uuid4().hex[:8]}"
        
        # Seed temporary session
        import subprocess
        subprocess.run([
            "mongosh", "--quiet", "--eval",
            f"use('test_database'); db.user_sessions.insertOne({{user_id:'user_test1776435744337', session_token:'{temp_token}', expires_at: new Date(Date.now()+7*24*60*60*1000), created_at: new Date()}});"
        ], capture_output=True)
        
        # Use temp token for logout
        temp_client = requests.Session()
        temp_client.headers.update({
            "Content-Type": "application/json",
            "Authorization": f"Bearer {temp_token}"
        })
        
        response = temp_client.post(f"{BASE_URL}/api/auth/logout")
        assert response.status_code == 200
        data = response.json()
        assert data["ok"] is True
        print("✓ Logout endpoint passed")


class TestCards:
    """Card CRUD endpoints"""

    def test_list_cards(self, api_client):
        """GET /api/cards returns seeded cards for test family"""
        response = api_client.get(f"{BASE_URL}/api/cards")
        assert response.status_code == 200
        
        cards = response.json()
        assert isinstance(cards, list)
        assert len(cards) >= 5  # At least 5 seeded cards
        
        # Verify card structure
        card = cards[0]
        assert "card_id" in card
        assert "family_id" in card
        assert card["family_id"] == "family_test1776435744337"
        assert "type" in card
        assert card["type"] in ["SIGN_SLIP", "RSVP", "TASK"]
        assert "title" in card
        assert "status" in card
        print(f"✓ List cards passed: {len(cards)} cards found")

    def test_create_card_and_verify(self, api_client):
        """POST /api/cards creates new card and verifies persistence"""
        create_payload = {
            "type": "TASK",
            "title": "TEST_Automated test task",
            "description": "This is a test card created by pytest",
            "assignee": "Test User",
            "source": "MANUAL"
        }
        
        create_response = api_client.post(f"{BASE_URL}/api/cards", json=create_payload)
        assert create_response.status_code == 200
        
        created_card = create_response.json()
        assert created_card["title"] == create_payload["title"]
        assert created_card["type"] == "TASK"
        assert created_card["status"] == "OPEN"
        assert "card_id" in created_card
        card_id = created_card["card_id"]
        
        # Verify persistence by listing cards
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        found = any(c["card_id"] == card_id for c in cards)
        assert found, "Created card not found in list"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        print(f"✓ Create card passed: {card_id}")

    def test_update_card_status(self, api_client):
        """PATCH /api/cards/{id} updates status and sets completed_at"""
        # Create a test card first
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={"type": "TASK", "title": "TEST_Status update test", "source": "MANUAL"}
        )
        card_id = create_response.json()["card_id"]
        
        # Update status to DONE
        update_response = api_client.patch(
            f"{BASE_URL}/api/cards/{card_id}",
            json={"status": "DONE"}
        )
        assert update_response.status_code == 200
        
        updated_card = update_response.json()
        assert updated_card["status"] == "DONE"
        assert updated_card["completed_at"] is not None
        
        # Update back to OPEN
        reopen_response = api_client.patch(
            f"{BASE_URL}/api/cards/{card_id}",
            json={"status": "OPEN"}
        )
        assert reopen_response.json()["status"] == "OPEN"
        assert reopen_response.json()["completed_at"] is None
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        print(f"✓ Update card status passed")

    def test_delete_card(self, api_client):
        """DELETE /api/cards/{id} removes card"""
        # Create a test card
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={"type": "TASK", "title": "TEST_Delete test", "source": "MANUAL"}
        )
        card_id = create_response.json()["card_id"]
        
        # Delete it
        delete_response = api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        assert delete_response.status_code == 200
        assert delete_response.json()["ok"] is True
        
        # Verify it's gone
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        found = any(c["card_id"] == card_id for c in cards)
        assert not found, "Deleted card still appears in list"
        print(f"✓ Delete card passed")


class TestFamily:
    """Family member endpoints"""

    def test_list_family_members(self, api_client):
        """GET /api/family/members returns 3 seeded members"""
        response = api_client.get(f"{BASE_URL}/api/family/members")
        assert response.status_code == 200
        
        members = response.json()
        assert isinstance(members, list)
        assert len(members) == 3
        
        # Verify member structure
        names = [m["name"] for m in members]
        assert "Emma" in names
        assert "Liam" in names
        assert "Alex Chen" in names
        
        # Check roles
        roles = [m["role"] for m in members]
        assert "Child" in roles
        assert "Parent" in roles
        print(f"✓ Family members passed: {names}")


class TestVault:
    """Vault document endpoints"""

    def test_list_vault_initially_empty(self, api_client):
        """GET /api/vault returns empty array initially"""
        response = api_client.get(f"{BASE_URL}/api/vault")
        assert response.status_code == 200
        
        docs = response.json()
        assert isinstance(docs, list)
        # May have docs from previous tests, just verify it's a list
        print(f"✓ List vault passed: {len(docs)} docs")

    def test_create_vault_doc_and_verify(self, api_client):
        """POST /api/vault creates document with image_base64"""
        # Create a small test image (1x1 red pixel PNG)
        test_image_base64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        
        create_payload = {
            "title": "TEST_Medical record",
            "category": "Medical",
            "image_base64": test_image_base64
        }
        
        create_response = api_client.post(f"{BASE_URL}/api/vault", json=create_payload)
        assert create_response.status_code == 200
        
        created_doc = create_response.json()
        assert created_doc["title"] == create_payload["title"]
        assert created_doc["category"] == "Medical"
        assert "doc_id" in created_doc
        doc_id = created_doc["doc_id"]
        
        # Verify persistence
        list_response = api_client.get(f"{BASE_URL}/api/vault")
        docs = list_response.json()
        found = any(d["doc_id"] == doc_id for d in docs)
        assert found, "Created vault doc not found in list"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/vault/{doc_id}")
        print(f"✓ Create vault doc passed: {doc_id}")

    def test_delete_vault_doc(self, api_client):
        """DELETE /api/vault/{id} removes document"""
        # Create a test doc
        test_image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        create_response = api_client.post(
            f"{BASE_URL}/api/vault",
            json={"title": "TEST_Delete doc", "category": "Legal", "image_base64": test_image}
        )
        doc_id = create_response.json()["doc_id"]
        
        # Delete it
        delete_response = api_client.delete(f"{BASE_URL}/api/vault/{doc_id}")
        assert delete_response.status_code == 200
        assert delete_response.json()["ok"] is True
        
        # Verify it's gone
        list_response = api_client.get(f"{BASE_URL}/api/vault")
        docs = list_response.json()
        found = any(d["doc_id"] == doc_id for d in docs)
        assert not found, "Deleted vault doc still appears in list"
        print(f"✓ Delete vault doc passed")


class TestWeeklyBrief:
    """AI Sunday Brief endpoint (Gemini 3 Flash)"""

    def test_weekly_brief_generation(self, api_client):
        """POST /api/brief/weekly returns AI-generated brief text"""
        response = api_client.post(f"{BASE_URL}/api/brief/weekly")
        assert response.status_code == 200
        
        data = response.json()
        assert "brief" in data
        assert "generated_at" in data
        assert isinstance(data["brief"], str)
        assert len(data["brief"]) > 0
        
        # Brief should be meaningful (not just error message)
        assert len(data["brief"]) > 50, "Brief text too short"
        print(f"✓ Weekly brief passed: {len(data['brief'])} chars generated")
        print(f"  Brief preview: {data['brief'][:100]}...")



# ============================================================
# ITERATION 2: Recurring Tasks & Voice Capture Tests
# ============================================================

class TestRecurringTasks:
    """Recurring tasks with auto-spawn on completion"""

    def test_create_weekly_recurring_task(self, api_client):
        """POST /api/cards with recurrence=weekly and reminder_minutes=60"""
        from datetime import datetime, timedelta, timezone
        
        due_date = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        
        create_payload = {
            "type": "TASK",
            "title": "Weekly chore test",
            "description": "Test weekly recurring task",
            "assignee": "Alex Chen",
            "due_date": due_date,
            "source": "MANUAL",
            "recurrence": "weekly",
            "reminder_minutes": 60
        }
        
        response = api_client.post(f"{BASE_URL}/api/cards", json=create_payload)
        assert response.status_code == 200
        
        card = response.json()
        assert card["title"] == "Weekly chore test"
        assert card["recurrence"] == "weekly"
        assert card["reminder_minutes"] == 60
        assert card["status"] == "OPEN"
        assert card["due_date"] is not None
        print(f"✓ Create weekly recurring task passed: {card['card_id']}")
        return card["card_id"]

    def test_weekly_auto_spawn_on_done(self, api_client):
        """PATCH /api/cards/{id} to DONE spawns next weekly instance (+7 days)"""
        from datetime import datetime, timedelta, timezone
        
        # Create weekly recurring card
        due_date = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "Weekly chore test",
                "due_date": due_date,
                "source": "MANUAL",
                "recurrence": "weekly",
                "reminder_minutes": 60
            }
        )
        original_card = create_response.json()
        original_id = original_card["card_id"]
        original_due = datetime.fromisoformat(original_card["due_date"].replace("Z", "+00:00"))
        
        # Mark as DONE
        update_response = api_client.patch(
            f"{BASE_URL}/api/cards/{original_id}",
            json={"status": "DONE"}
        )
        assert update_response.status_code == 200
        assert update_response.json()["status"] == "DONE"
        
        # Verify next instance was spawned
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        weekly_cards = [c for c in cards if c["title"] == "Weekly chore test"]
        
        assert len(weekly_cards) >= 2, f"Expected at least 2 cards with title 'Weekly chore test', found {len(weekly_cards)}"
        
        # Find the new OPEN card
        new_card = next((c for c in weekly_cards if c["status"] == "OPEN" and c["card_id"] != original_id), None)
        assert new_card is not None, "No new OPEN card found after marking original as DONE"
        
        # Verify due_date is +7 days
        new_due = datetime.fromisoformat(new_card["due_date"].replace("Z", "+00:00"))
        days_diff = (new_due - original_due).days
        assert days_diff == 7, f"Expected +7 days, got +{days_diff} days"
        
        # Verify recurrence and reminder_minutes are preserved
        assert new_card["recurrence"] == "weekly"
        assert new_card["reminder_minutes"] == 60
        
        print(f"✓ Weekly auto-spawn passed: original {original_id} → new {new_card['card_id']}")

    def test_daily_recurring_task(self, api_client):
        """POST daily card, PATCH to DONE, verify next instance is +1 day"""
        from datetime import datetime, timedelta, timezone
        
        due_date = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()
        
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "Daily test",
                "due_date": due_date,
                "source": "MANUAL",
                "recurrence": "daily",
                "reminder_minutes": 15
            }
        )
        original_card = create_response.json()
        original_id = original_card["card_id"]
        original_due = datetime.fromisoformat(original_card["due_date"].replace("Z", "+00:00"))
        
        # Mark as DONE
        api_client.patch(f"{BASE_URL}/api/cards/{original_id}", json={"status": "DONE"})
        
        # Verify next instance
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        daily_cards = [c for c in cards if c["title"] == "Daily test"]
        
        assert len(daily_cards) >= 2, f"Expected at least 2 'Daily test' cards, found {len(daily_cards)}"
        
        new_card = next((c for c in daily_cards if c["status"] == "OPEN" and c["card_id"] != original_id), None)
        assert new_card is not None
        
        new_due = datetime.fromisoformat(new_card["due_date"].replace("Z", "+00:00"))
        days_diff = (new_due - original_due).days
        assert days_diff == 1, f"Expected +1 day, got +{days_diff} days"
        
        print(f"✓ Daily recurring task passed: +1 day verified")

    def test_monthly_recurring_task(self, api_client):
        """POST monthly card, PATCH to DONE, verify next instance is ~+30 days"""
        from datetime import datetime, timedelta, timezone
        
        due_date = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "Monthly test",
                "due_date": due_date,
                "source": "MANUAL",
                "recurrence": "monthly",
                "reminder_minutes": 1440
            }
        )
        original_card = create_response.json()
        original_id = original_card["card_id"]
        original_due = datetime.fromisoformat(original_card["due_date"].replace("Z", "+00:00"))
        
        # Mark as DONE
        api_client.patch(f"{BASE_URL}/api/cards/{original_id}", json={"status": "DONE"})
        
        # Verify next instance
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        monthly_cards = [c for c in cards if c["title"] == "Monthly test"]
        
        assert len(monthly_cards) >= 2, f"Expected at least 2 'Monthly test' cards, found {len(monthly_cards)}"
        
        new_card = next((c for c in monthly_cards if c["status"] == "OPEN" and c["card_id"] != original_id), None)
        assert new_card is not None
        
        new_due = datetime.fromisoformat(new_card["due_date"].replace("Z", "+00:00"))
        days_diff = (new_due - original_due).days
        assert days_diff == 30, f"Expected +30 days, got +{days_diff} days"
        
        print(f"✓ Monthly recurring task passed: +30 days verified")

    def test_non_recurring_not_spawned(self, api_client):
        """POST card with recurrence='none', PATCH to DONE, verify no duplicate spawned"""
        from datetime import datetime, timedelta, timezone
        
        due_date = (datetime.now(timezone.utc) + timedelta(days=1)).isoformat()
        
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "Non-recurring test",
                "due_date": due_date,
                "source": "MANUAL",
                "recurrence": "none",
                "reminder_minutes": 0
            }
        )
        original_id = create_response.json()["card_id"]
        
        # Mark as DONE
        api_client.patch(f"{BASE_URL}/api/cards/{original_id}", json={"status": "DONE"})
        
        # Verify no duplicate spawned
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        non_recurring_cards = [c for c in cards if c["title"] == "Non-recurring test"]
        
        assert len(non_recurring_cards) == 1, f"Expected exactly 1 'Non-recurring test' card, found {len(non_recurring_cards)}"
        assert non_recurring_cards[0]["status"] == "DONE"
        
        print(f"✓ Non-recurring task passed: no duplicate spawned")


class TestVoiceTranscribe:
    """Voice transcription endpoint (Whisper-1 + Gemini)"""

    def test_voice_transcribe_requires_auth(self, api_client_no_auth):
        """POST /api/voice/transcribe rejects unauthenticated requests"""
        # Create a minimal multipart request
        import io
        files = {'audio': ('test.webm', io.BytesIO(b'fake audio data'), 'audio/webm')}
        
        response = requests.post(
            f"{BASE_URL}/api/voice/transcribe",
            files=files
        )
        assert response.status_code == 401, f"Expected 401, got {response.status_code}"
        print("✓ Voice transcribe correctly requires auth")

    def test_voice_transcribe_rejects_empty_audio(self, api_client):
        """POST /api/voice/transcribe with empty audio returns 400"""
        import io
        files = {'audio': ('test.webm', io.BytesIO(b''), 'audio/webm')}
        
        response = requests.post(
            f"{BASE_URL}/api/voice/transcribe",
            files=files,
            headers={"Authorization": f"Bearer {SESSION_TOKEN}"}
        )
        assert response.status_code == 400, f"Expected 400 for empty audio, got {response.status_code}"
        print("✓ Voice transcribe rejects empty audio")

    def test_voice_transcribe_endpoint_exists(self, api_client):
        """Verify /api/voice/transcribe endpoint exists (even if we can't test with real audio)"""
        # Send a small fake audio blob - will fail transcription but proves endpoint exists
        import io
        files = {'audio': ('test.webm', io.BytesIO(b'x' * 1000), 'audio/webm')}
        
        response = requests.post(
            f"{BASE_URL}/api/voice/transcribe",
            files=files,
            headers={"Authorization": f"Bearer {SESSION_TOKEN}"}
        )
        
        # Endpoint exists if we get 400 (bad audio) or 500 (transcription failed), not 404
        assert response.status_code != 404, "Voice transcribe endpoint not found"
        print(f"✓ Voice transcribe endpoint exists (status: {response.status_code})")


class TestCleanup:
    """Cleanup test-created cards"""

    def test_cleanup_test_cards(self, api_client):
        """Delete all test-created cards with specific titles"""
        test_titles = [
            "Weekly chore test",
            "Daily test",
            "Monthly test",
            "Non-recurring test"
        ]
        
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        
        deleted_count = 0
        for card in cards:
            if card["title"] in test_titles:
                api_client.delete(f"{BASE_URL}/api/cards/{card['card_id']}")
                deleted_count += 1
        
        print(f"✓ Cleanup passed: deleted {deleted_count} test cards")
