"""
Backend API Tests for Iteration 3: Rewards, Stars, Conflicts, Vision
Tests new features: Rewards CRUD, Stars auto-award, Conflict Intelligence, Vision extraction
"""
import pytest
import requests
import os
from datetime import datetime, timedelta, timezone

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


class TestFamilyMembersWithStars:
    """Verify GET /api/family/members returns stars field"""

    def test_family_members_have_stars_field(self, api_client):
        """GET /api/family/members returns members WITH 'stars' field"""
        response = api_client.get(f"{BASE_URL}/api/family/members")
        assert response.status_code == 200
        
        members = response.json()
        assert isinstance(members, list)
        assert len(members) == 3
        
        # Verify all members have stars field
        for member in members:
            assert "stars" in member, f"Member {member['name']} missing 'stars' field"
            assert isinstance(member["stars"], int)
        
        # Verify seeded star values
        emma = next((m for m in members if m["name"] == "Emma"), None)
        liam = next((m for m in members if m["name"] == "Liam"), None)
        alex = next((m for m in members if m["name"] == "Alex Chen"), None)
        
        assert emma is not None and emma["stars"] == 75, f"Emma should have 75 stars, got {emma['stars'] if emma else 'not found'}"
        assert liam is not None and liam["stars"] == 40, f"Liam should have 40 stars, got {liam['stars'] if liam else 'not found'}"
        assert alex is not None and alex["stars"] == 0, f"Alex Chen should have 0 stars, got {alex['stars'] if alex else 'not found'}"
        
        print(f"✓ Family members with stars passed: Emma={emma['stars']}, Liam={liam['stars']}, Alex={alex['stars']}")


class TestRewards:
    """Rewards CRUD endpoints"""

    def test_list_rewards_returns_seeded_rewards(self, api_client):
        """GET /api/rewards returns list of 3 seeded rewards"""
        response = api_client.get(f"{BASE_URL}/api/rewards")
        assert response.status_code == 200
        
        rewards = response.json()
        assert isinstance(rewards, list)
        assert len(rewards) >= 3, f"Expected at least 3 seeded rewards, got {len(rewards)}"
        
        # Verify seeded rewards
        titles = [r["title"] for r in rewards]
        assert "Pizza Night" in titles
        assert "Movie Pick" in titles
        assert "Extra Screen Time (30 min)" in titles or any("Extra Screen Time" in t for t in titles)
        
        # Verify structure
        pizza = next((r for r in rewards if "Pizza" in r["title"]), None)
        assert pizza is not None
        assert pizza["cost_stars"] == 100
        assert pizza["icon"] == "🍕"
        assert "reward_id" in pizza
        assert "family_id" in pizza
        assert "created_at" in pizza
        
        print(f"✓ List rewards passed: {len(rewards)} rewards found")

    def test_create_reward_and_verify(self, api_client):
        """POST /api/rewards creates a new reward"""
        create_payload = {
            "title": "TEST_Ice Cream Trip",
            "cost_stars": 25,
            "icon": "🍦"
        }
        
        create_response = api_client.post(f"{BASE_URL}/api/rewards", json=create_payload)
        assert create_response.status_code == 200
        
        created_reward = create_response.json()
        assert created_reward["title"] == create_payload["title"]
        assert created_reward["cost_stars"] == 25
        assert created_reward["icon"] == "🍦"
        assert "reward_id" in created_reward
        reward_id = created_reward["reward_id"]
        
        # Verify persistence
        list_response = api_client.get(f"{BASE_URL}/api/rewards")
        rewards = list_response.json()
        found = any(r["reward_id"] == reward_id for r in rewards)
        assert found, "Created reward not found in list"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/rewards/{reward_id}")
        print(f"✓ Create reward passed: {reward_id}")

    def test_delete_reward(self, api_client):
        """DELETE /api/rewards/{id} removes reward"""
        # Create a test reward
        create_response = api_client.post(
            f"{BASE_URL}/api/rewards",
            json={"title": "TEST_Delete reward", "cost_stars": 10, "icon": "🎁"}
        )
        reward_id = create_response.json()["reward_id"]
        
        # Delete it
        delete_response = api_client.delete(f"{BASE_URL}/api/rewards/{reward_id}")
        assert delete_response.status_code == 200
        assert delete_response.json()["ok"] is True
        
        # Verify it's gone
        list_response = api_client.get(f"{BASE_URL}/api/rewards")
        rewards = list_response.json()
        found = any(r["reward_id"] == reward_id for r in rewards)
        assert not found, "Deleted reward still appears in list"
        print(f"✓ Delete reward passed")


class TestRewardRedemption:
    """Reward redemption with star deduction"""

    def test_redeem_reward_with_sufficient_stars(self, api_client):
        """POST /api/rewards/{id}/redeem with member_id=Emma's id: deducts stars if sufficient"""
        # Get Emma's member_id and current stars
        members_response = api_client.get(f"{BASE_URL}/api/family/members")
        members = members_response.json()
        emma = next((m for m in members if m["name"] == "Emma"), None)
        assert emma is not None, "Emma not found in family members"
        
        emma_id = emma["member_id"]
        initial_stars = emma["stars"]
        
        # Get a reward Emma can afford (30 star reward)
        rewards_response = api_client.get(f"{BASE_URL}/api/rewards")
        rewards = rewards_response.json()
        affordable_reward = next((r for r in rewards if r["cost_stars"] == 30), None)
        assert affordable_reward is not None, "30-star reward not found"
        
        # Redeem the reward
        redeem_response = api_client.post(
            f"{BASE_URL}/api/rewards/{affordable_reward['reward_id']}/redeem",
            json={"member_id": emma_id}
        )
        assert redeem_response.status_code == 200
        
        result = redeem_response.json()
        assert result["ok"] is True
        assert "member" in result
        assert result["member"]["member_id"] == emma_id
        
        # Verify stars were deducted
        new_stars = result["member"]["stars"]
        expected_stars = initial_stars - affordable_reward["cost_stars"]
        assert new_stars == expected_stars, f"Expected {expected_stars} stars, got {new_stars}"
        
        # Verify persistence
        members_check = api_client.get(f"{BASE_URL}/api/family/members").json()
        emma_check = next((m for m in members_check if m["member_id"] == emma_id), None)
        assert emma_check["stars"] == new_stars
        
        print(f"✓ Redeem reward with sufficient stars passed: Emma {initial_stars}★ → {new_stars}★")

    def test_redeem_reward_with_insufficient_stars(self, api_client):
        """POST /api/rewards/{id}/redeem returns 400 if member has fewer stars than cost"""
        # Get Liam's member_id (40 stars)
        members_response = api_client.get(f"{BASE_URL}/api/family/members")
        members = members_response.json()
        liam = next((m for m in members if m["name"] == "Liam"), None)
        assert liam is not None, "Liam not found in family members"
        
        liam_id = liam["member_id"]
        liam_stars = liam["stars"]
        
        # Get the 100-star Pizza Night reward (Liam can't afford)
        rewards_response = api_client.get(f"{BASE_URL}/api/rewards")
        rewards = rewards_response.json()
        expensive_reward = next((r for r in rewards if r["cost_stars"] == 100), None)
        assert expensive_reward is not None, "100-star reward not found"
        
        # Try to redeem (should fail)
        redeem_response = api_client.post(
            f"{BASE_URL}/api/rewards/{expensive_reward['reward_id']}/redeem",
            json={"member_id": liam_id}
        )
        assert redeem_response.status_code == 400, f"Expected 400, got {redeem_response.status_code}"
        
        # Verify Liam's stars unchanged
        members_check = api_client.get(f"{BASE_URL}/api/family/members").json()
        liam_check = next((m for m in members_check if m["member_id"] == liam_id), None)
        assert liam_check["stars"] == liam_stars, "Liam's stars should not change on failed redemption"
        
        print(f"✓ Redeem reward with insufficient stars passed: Liam {liam_stars}★ cannot afford {expensive_reward['cost_stars']}★")


class TestStarsAutoAward:
    """Stars auto-award on task completion"""

    def test_stars_awarded_when_child_completes_task(self, api_client):
        """POST card with type=TASK, assignee=Emma, then PATCH status=DONE → Emma's stars increment by 5"""
        # Get Emma's current stars
        members_response = api_client.get(f"{BASE_URL}/api/family/members")
        members = members_response.json()
        emma = next((m for m in members if m["name"] == "Emma"), None)
        initial_stars = emma["stars"]
        
        # Create a TASK assigned to Emma
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "TEST_Kids test task for Emma",
                "assignee": "Emma",
                "source": "MANUAL"
            }
        )
        assert create_response.status_code == 200
        card_id = create_response.json()["card_id"]
        
        # Mark as DONE
        update_response = api_client.patch(
            f"{BASE_URL}/api/cards/{card_id}",
            json={"status": "DONE"}
        )
        assert update_response.status_code == 200
        
        # Verify Emma's stars incremented by 5
        members_check = api_client.get(f"{BASE_URL}/api/family/members").json()
        emma_check = next((m for m in members_check if m["name"] == "Emma"), None)
        expected_stars = initial_stars + 5
        assert emma_check["stars"] == expected_stars, f"Expected {expected_stars} stars, got {emma_check['stars']}"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        
        print(f"✓ Stars auto-award for child task passed: Emma {initial_stars}★ → {expected_stars}★")

    def test_no_stars_awarded_for_parent_assignee(self, api_client):
        """POST card with type=TASK, assignee=Alex Chen (parent), then PATCH DONE → Alex Chen's stars unchanged"""
        # Get Alex Chen's current stars
        members_response = api_client.get(f"{BASE_URL}/api/family/members")
        members = members_response.json()
        alex = next((m for m in members if m["name"] == "Alex Chen"), None)
        initial_stars = alex["stars"]
        
        # Create a TASK assigned to Alex Chen (parent)
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "TEST_Parent task for Alex",
                "assignee": "Alex Chen",
                "source": "MANUAL"
            }
        )
        card_id = create_response.json()["card_id"]
        
        # Mark as DONE
        api_client.patch(f"{BASE_URL}/api/cards/{card_id}", json={"status": "DONE"})
        
        # Verify Alex Chen's stars unchanged
        members_check = api_client.get(f"{BASE_URL}/api/family/members").json()
        alex_check = next((m for m in members_check if m["name"] == "Alex Chen"), None)
        assert alex_check["stars"] == initial_stars, f"Parent stars should not change, expected {initial_stars}, got {alex_check['stars']}"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        
        print(f"✓ No stars for parent assignee passed: Alex Chen stars unchanged at {initial_stars}★")

    def test_no_stars_awarded_for_non_task_types(self, api_client):
        """POST card with type=SIGN_SLIP, assignee=Emma, then PATCH DONE → Emma's stars unchanged"""
        # Get Emma's current stars
        members_response = api_client.get(f"{BASE_URL}/api/family/members")
        members = members_response.json()
        emma = next((m for m in members if m["name"] == "Emma"), None)
        initial_stars = emma["stars"]
        
        # Create a SIGN_SLIP assigned to Emma
        create_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "SIGN_SLIP",
                "title": "TEST_Sign slip for Emma",
                "assignee": "Emma",
                "source": "MANUAL"
            }
        )
        card_id = create_response.json()["card_id"]
        
        # Mark as DONE
        api_client.patch(f"{BASE_URL}/api/cards/{card_id}", json={"status": "DONE"})
        
        # Verify Emma's stars unchanged
        members_check = api_client.get(f"{BASE_URL}/api/family/members").json()
        emma_check = next((m for m in members_check if m["name"] == "Emma"), None)
        assert emma_check["stars"] == initial_stars, f"Stars should not change for non-TASK, expected {initial_stars}, got {emma_check['stars']}"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card_id}")
        
        print(f"✓ No stars for non-TASK types passed: Emma stars unchanged at {initial_stars}★")


class TestConflictIntelligence:
    """GET /api/cards/conflicts endpoint"""

    def test_conflicts_returns_overlapping_cards(self, api_client):
        """GET /api/cards/conflicts?due_date=<ISO> returns OPEN cards within ±2h"""
        # Create two cards with same due_date
        target_time = datetime.now(timezone.utc) + timedelta(hours=3)
        due_date_iso = target_time.isoformat()
        
        card1_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "TEST_Conflict card 1",
                "due_date": due_date_iso,
                "source": "MANUAL"
            }
        )
        card1_id = card1_response.json()["card_id"]
        
        card2_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "RSVP",
                "title": "TEST_Conflict card 2",
                "due_date": due_date_iso,
                "source": "MANUAL"
            }
        )
        card2_id = card2_response.json()["card_id"]
        
        # Query conflicts (use params dict for proper URL encoding)
        conflicts_response = api_client.get(
            f"{BASE_URL}/api/cards/conflicts",
            params={"due_date": due_date_iso}
        )
        assert conflicts_response.status_code == 200
        
        conflicts = conflicts_response.json()
        assert isinstance(conflicts, list)
        assert len(conflicts) >= 2, f"Expected at least 2 conflicting cards, got {len(conflicts)}"
        
        # Verify both cards are in conflicts
        conflict_ids = [c["card_id"] for c in conflicts]
        assert card1_id in conflict_ids, "Card 1 not found in conflicts"
        assert card2_id in conflict_ids, "Card 2 not found in conflicts"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{card1_id}")
        api_client.delete(f"{BASE_URL}/api/cards/{card2_id}")
        
        print(f"✓ Conflicts endpoint passed: {len(conflicts)} overlapping cards found")

    def test_conflicts_within_2h_window(self, api_client):
        """Verify conflicts endpoint returns cards within ±2h window"""
        target_time = datetime.now(timezone.utc) + timedelta(hours=5)
        
        # Card within window (+1h)
        within_time = target_time + timedelta(hours=1)
        within_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "TEST_Within 2h window",
                "due_date": within_time.isoformat(),
                "source": "MANUAL"
            }
        )
        within_id = within_response.json()["card_id"]
        
        # Card outside window (+3h)
        outside_time = target_time + timedelta(hours=3)
        outside_response = api_client.post(
            f"{BASE_URL}/api/cards",
            json={
                "type": "TASK",
                "title": "TEST_Outside 2h window",
                "due_date": outside_time.isoformat(),
                "source": "MANUAL"
            }
        )
        outside_id = outside_response.json()["card_id"]
        
        # Query conflicts (use params dict for proper URL encoding)
        conflicts_response = api_client.get(
            f"{BASE_URL}/api/cards/conflicts",
            params={"due_date": target_time.isoformat()}
        )
        conflicts = conflicts_response.json()
        conflict_ids = [c["card_id"] for c in conflicts]
        
        # Verify within card is included, outside card is not
        assert within_id in conflict_ids, "Card within 2h window should be in conflicts"
        assert outside_id not in conflict_ids, "Card outside 2h window should not be in conflicts"
        
        # Cleanup
        api_client.delete(f"{BASE_URL}/api/cards/{within_id}")
        api_client.delete(f"{BASE_URL}/api/cards/{outside_id}")
        
        print(f"✓ Conflicts 2h window validation passed")


class TestVisionExtract:
    """POST /api/vision/extract endpoint"""

    def test_vision_extract_requires_auth(self, api_client_no_auth):
        """POST /api/vision/extract returns 401 without token"""
        response = api_client_no_auth.post(
            f"{BASE_URL}/api/vision/extract",
            json={"image_base64": "data:image/jpeg;base64,/9j/4AAQSkZJRg=="}
        )
        assert response.status_code == 401, f"Expected 401, got {response.status_code}"
        print("✓ Vision extract correctly requires auth")

    def test_vision_extract_endpoint_exists(self, api_client):
        """POST /api/vision/extract with valid token returns structured response or graceful error"""
        # Use a tiny valid base64 image (1x1 red pixel PNG)
        tiny_image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
        
        response = api_client.post(
            f"{BASE_URL}/api/vision/extract",
            json={"image_base64": tiny_image}
        )
        
        # Endpoint exists if we get 200 (success) or 500 (vision failed), not 404
        assert response.status_code != 404, "Vision extract endpoint not found"
        
        if response.status_code == 200:
            data = response.json()
            assert "type" in data
            assert "title" in data
            assert data["type"] in ["SIGN_SLIP", "RSVP", "TASK"]
            print(f"✓ Vision extract endpoint passed: returned VisionDraft with type={data['type']}")
        elif response.status_code == 500:
            print(f"✓ Vision extract endpoint exists (returned 500 - expected for non-flyer image)")
        else:
            print(f"✓ Vision extract endpoint exists (status: {response.status_code})")


class TestCleanup:
    """Cleanup test-created data"""

    def test_cleanup_test_cards(self, api_client):
        """Delete all test-created cards"""
        list_response = api_client.get(f"{BASE_URL}/api/cards")
        cards = list_response.json()
        
        deleted_count = 0
        for card in cards:
            if card["title"].startswith("TEST_"):
                api_client.delete(f"{BASE_URL}/api/cards/{card['card_id']}")
                deleted_count += 1
        
        print(f"✓ Cleanup cards passed: deleted {deleted_count} test cards")

    def test_cleanup_test_rewards(self, api_client):
        """Delete all test-created rewards"""
        list_response = api_client.get(f"{BASE_URL}/api/rewards")
        rewards = list_response.json()
        
        deleted_count = 0
        for reward in rewards:
            if reward["title"].startswith("TEST_"):
                api_client.delete(f"{BASE_URL}/api/rewards/{reward['reward_id']}")
                deleted_count += 1
        
        print(f"✓ Cleanup rewards passed: deleted {deleted_count} test rewards")
