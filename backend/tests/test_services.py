import unittest

from tests import support
from tests.support import parametrize_over_backends

from app.core.exceptions import (
    ConflictError,
    NotFoundError,
    UnauthorizedError,
    ValidationAppError,
)
from app.services import assistant_service, auth_service, site_service


class BaseAuthServiceTests:
    def test_authenticate_success(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        assistant = auth_service.authenticate("j.smith@baxall.co.uk", "baxall123")
        self.assertEqual(assistant["email"], "j.smith@baxall.co.uk")

    def test_authenticate_wrong_password(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        with self.assertRaises(UnauthorizedError):
            auth_service.authenticate("j.smith@baxall.co.uk", "wrong-password")

    def test_authenticate_unknown_email(self):
        with self.assertRaises(UnauthorizedError):
            auth_service.authenticate("nobody@baxall.co.uk", "whatever")

    def test_issue_token_round_trip(self):
        assistant = self.make_assistant(email="j.smith@baxall.co.uk")
        token_data = auth_service.issue_token(assistant)
        self.assertEqual(token_data["token_type"], "bearer")
        self.assertIn("access_token", token_data)
        self.assertGreater(token_data["expires_in"], 0)

    def test_get_assistant_by_id(self):
        created = self.make_assistant()
        found = auth_service.get_assistant_by_id(created["assistant_id"])
        self.assertEqual(found["assistant_id"], created["assistant_id"])

    def test_get_assistant_by_id_missing(self):
        self.assertIsNone(auth_service.get_assistant_by_id("nope"))


class BaseAssistantServiceTests:
    def test_create_assistant(self):
        created = assistant_service.create_assistant(
            full_name="  Dana Reid  ",
            email="  D.Reid@Baxall.co.uk  ",
            password="baxall123",
            role="Foreman",
        )

        self.assertEqual(created["full_name"], "Dana Reid")
        self.assertEqual(created["email"], "d.reid@baxall.co.uk")
        self.assertNotEqual(created["password_hash"], "baxall123")

    def test_create_assistant_missing_fields(self):
        with self.assertRaises(ValidationAppError):
            assistant_service.create_assistant(full_name="", email="", password="")

    def test_create_assistant_duplicate_email(self):
        assistant_service.create_assistant(
            full_name="First", email="dup@baxall.co.uk", password="baxall123"
        )
        with self.assertRaises(ConflictError):
            assistant_service.create_assistant(
                full_name="Second", email="dup@baxall.co.uk", password="baxall123"
            )

    def test_get_assistant_not_found(self):
        with self.assertRaises(NotFoundError):
            assistant_service.get_assistant("nope")

    def test_update_profile_only_touches_editable_fields(self):
        created = self.make_assistant()
        updated = assistant_service.update_profile(
            created["assistant_id"],
            {"full_name": "Updated Name", "email": "hacker@evil.com"},
        )
        self.assertEqual(updated["full_name"], "Updated Name")

        self.assertEqual(updated["email"], created["email"])

    def test_update_profile_not_found(self):
        with self.assertRaises(NotFoundError):
            assistant_service.update_profile("nope", {"full_name": "X"})

    def test_delete_assistant(self):
        created = self.make_assistant()
        assistant_service.delete_assistant(created["assistant_id"])
        with self.assertRaises(NotFoundError):
            assistant_service.get_assistant(created["assistant_id"])

    def test_delete_assistant_not_found(self):
        with self.assertRaises(NotFoundError):
            assistant_service.delete_assistant("nope")


class BaseSiteServiceTests:
    def test_create_site_requires_name_and_address(self):
        with self.assertRaises(ValidationAppError):
            site_service.create_site(site_name="", address="")

    def test_create_site_rejects_unknown_assigned_assistant(self):
        with self.assertRaises(ValidationAppError):
            site_service.create_site(
                site_name="Tower A",
                address="1 Example St",
                assigned_assistant_id="nope",
            )

    def test_create_site_success(self):
        assistant = self.make_assistant()
        site = site_service.create_site(
            site_name="Tower A",
            address="1 Example St",
            assigned_assistant_id=assistant["assistant_id"],
        )
        self.assertEqual(site["site_name"], "Tower A")
        self.assertEqual(site["assigned_assistant_id"], assistant["assistant_id"])

    def test_get_site_not_found(self):
        with self.assertRaises(NotFoundError):
            site_service.get_site("nope")

    def test_get_site_detail_includes_assistant(self):
        assistant = self.make_assistant()
        site = self.make_site(assigned_assistant_id=assistant["assistant_id"])
        detail = site_service.get_site_detail(site["site_id"])
        self.assertEqual(
            detail["assigned_assistant"]["assistant_id"], assistant["assistant_id"]
        )

    def test_get_site_detail_no_assigned_assistant(self):
        site = self.make_site(assigned_assistant_id=None)
        detail = site_service.get_site_detail(site["site_id"])
        self.assertIsNone(detail["assigned_assistant"])

    def test_update_site_only_touches_editable_fields(self):
        site = self.make_site()
        updated = site_service.update_site(
            site["site_id"], {"phase": "Groundworks", "status": "archived"}
        )
        self.assertEqual(updated["phase"], "Groundworks")

        self.assertEqual(updated["status"], "active")

    def test_update_site_not_found(self):
        with self.assertRaises(NotFoundError):
            site_service.update_site("nope", {"phase": "X"})

    def test_delete_site(self):
        site = self.make_site()
        site_service.delete_site(site["site_id"])
        with self.assertRaises(NotFoundError):
            site_service.get_site(site["site_id"])

    def test_delete_site_not_found(self):
        with self.assertRaises(NotFoundError):
            site_service.delete_site("nope")

    def test_get_active_site_for_assistant_prefers_own_active_site(self):
        assistant = self.make_assistant()
        other = self.make_assistant(email="other@baxall.co.uk")
        self.make_site(
            site_name="Someone else's",
            assigned_assistant_id=other["assistant_id"],
            status="active",
        )
        mine = self.make_site(
            site_name="Mine",
            assigned_assistant_id=assistant["assistant_id"],
            status="active",
        )
        chosen = site_service.get_active_site_for_assistant(assistant["assistant_id"])
        self.assertEqual(chosen["site_id"], mine["site_id"])

    def test_get_active_site_for_assistant_falls_back_to_any_active_site(self):
        assistant = self.make_assistant()
        fallback = self.make_site(
            site_name="Unassigned active site",
            assigned_assistant_id=None,
            status="active",
        )
        chosen = site_service.get_active_site_for_assistant(assistant["assistant_id"])
        self.assertEqual(chosen["site_id"], fallback["site_id"])

    def test_get_active_site_for_assistant_returns_none_when_no_sites(self):
        assistant = self.make_assistant()
        self.assertIsNone(
            site_service.get_active_site_for_assistant(assistant["assistant_id"])
        )


for _base, _name in (
    (BaseAuthServiceTests, "AuthServiceTests"),
    (BaseAssistantServiceTests, "AssistantServiceTests"),
    (BaseSiteServiceTests, "SiteServiceTests"),
):
    _base.__name__ = _name
    globals().update(parametrize_over_backends(_base, __name__))
del _base, _name


if __name__ == "__main__":
    unittest.main()
