import unittest

from tests import support
from tests.support import parametrize_over_backends

from app.core.utils import new_id


class BaseAssistantRepositoryTests:
    def test_add_and_get(self):
        created = self.make_assistant(email="a@example.com")
        fetched = self.registry.assistants.get(created["assistant_id"])
        self.assertEqual(fetched["email"], "a@example.com")

    def test_get_missing_returns_none(self):
        self.assertIsNone(self.registry.assistants.get("does-not-exist"))

    def test_find_by_email(self):
        self.make_assistant(email="findme@example.com")
        found = self.registry.assistants.find_by_email("findme@example.com")
        self.assertIsNotNone(found)
        self.assertEqual(found["email"], "findme@example.com")

    def test_find_by_email_missing_returns_none(self):
        self.assertIsNone(self.registry.assistants.find_by_email("nope@example.com"))

    def test_list_returns_all(self):
        self.make_assistant(email="a1@example.com")
        self.make_assistant(email="a2@example.com")
        emails = {a["email"] for a in self.registry.assistants.list()}
        self.assertEqual(emails, {"a1@example.com", "a2@example.com"})

    def test_update_changes_fields(self):
        created = self.make_assistant()
        updated = self.registry.assistants.update(
            created["assistant_id"], {"full_name": "New Name"}
        )
        self.assertEqual(updated["full_name"], "New Name")
        self.assertEqual(
            self.registry.assistants.get(created["assistant_id"])["full_name"],
            "New Name",
        )

    def test_update_missing_returns_none(self):
        result = self.registry.assistants.update("nope", {"full_name": "X"})
        self.assertIsNone(result)

    def test_delete(self):
        created = self.make_assistant()
        self.assertTrue(self.registry.assistants.delete(created["assistant_id"]))
        self.assertIsNone(self.registry.assistants.get(created["assistant_id"]))

    def test_delete_missing_returns_false(self):
        self.assertFalse(self.registry.assistants.delete("nope"))


class BaseSiteRepositoryTests:
    def test_add_and_get(self):
        site = self.make_site(site_name="Tower A")
        fetched = self.registry.sites.get(site["site_id"])
        self.assertEqual(fetched["site_name"], "Tower A")

    def test_list_filtered_by_assigned_assistant(self):
        assistant = self.make_assistant()
        mine = self.make_site(
            site_name="Mine", assigned_assistant_id=assistant["assistant_id"]
        )
        self.make_site(site_name="Not mine", assigned_assistant_id=None)

        results = self.registry.sites.list(
            assigned_assistant_id=assistant["assistant_id"]
        )
        ids = {s["site_id"] for s in results}
        self.assertIn(mine["site_id"], ids)
        self.assertEqual(len(results), 1)

    def test_update_and_delete(self):
        site = self.make_site()
        updated = self.registry.sites.update(site["site_id"], {"phase": "Groundworks"})
        self.assertEqual(updated["phase"], "Groundworks")
        self.assertTrue(self.registry.sites.delete(site["site_id"]))
        self.assertIsNone(self.registry.sites.get(site["site_id"]))


class BaseReportRepositoryTests:
    def test_add_list_get_delete(self):
        site = self.make_site()
        record = {
            "id": new_id("incident"),
            "site_id": site["site_id"],
            "report_type": "incident",
            "status": "signed_off",
            "report_date": "2026-01-01",
            "approved_by": None,
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "fields": {"project": "Riverside"},
            "pdf_path": None,
        }
        self.registry.reports.add(record)

        fetched = self.registry.reports.get(record["id"])
        self.assertEqual(fetched["fields"]["project"], "Riverside")

        listed = self.registry.reports.list(site_id=site["site_id"])
        self.assertEqual(len(listed), 1)

        self.assertTrue(self.registry.reports.delete(record["id"]))
        self.assertIsNone(self.registry.reports.get(record["id"]))


class BasePictureAndVoiceNoteRepositoryTests:
    def test_pictures_add_list_get_delete(self):
        site = self.make_site()
        record = {
            "id": new_id("pic"),
            "site_id": site["site_id"],
            "assistant_id": None,
            "file_path": "pictures/example.jpg",
            "caption": "Trench edge",
            "created_at": "2026-01-01T00:00:00Z",
        }
        self.registry.pictures.add(record)
        self.assertEqual(len(self.registry.pictures.list(site["site_id"])), 1)
        self.assertIsNotNone(self.registry.pictures.get(record["id"]))
        self.assertTrue(self.registry.pictures.delete(record["id"]))
        self.assertIsNone(self.registry.pictures.get(record["id"]))

    def test_voice_notes_add_list_get_delete(self):
        site = self.make_site()
        record = {
            "id": new_id("voice"),
            "site_id": site["site_id"],
            "assistant_id": None,
            "transcript": "Poured concrete to section 4A.",
            "file_path": "voice/example.m4a",
            "created_at": "2026-01-01T00:00:00Z",
        }
        self.registry.voice_notes.add(record)
        self.assertEqual(len(self.registry.voice_notes.list(site["site_id"])), 1)
        self.assertIsNotNone(self.registry.voice_notes.get(record["id"]))
        self.assertTrue(self.registry.voice_notes.delete(record["id"]))
        self.assertIsNone(self.registry.voice_notes.get(record["id"]))





for _base in (
    BaseAssistantRepositoryTests,
    BaseSiteRepositoryTests,
    BaseReportRepositoryTests,
    BasePictureAndVoiceNoteRepositoryTests,
):
    globals().update(parametrize_over_backends(_base, __name__))
del _base


if __name__ == "__main__":
    unittest.main()
