import unittest

from tests import support
from tests.support import parametrize_over_backends

from app.core.exceptions import ValidationAppError
from app.services import incident_report_service


class BaseIncidentReportServiceTests:
    def test_generate_draft_unknown_site(self):
        with self.assertRaises(ValidationAppError):
            incident_report_service.generate_draft("nope")

    def test_generate_draft_returns_blank_fields_when_ai_unavailable(self):


        site = self.make_site()
        draft = incident_report_service.generate_draft(site["site_id"])
        self.assertEqual(draft["site_id"], site["site_id"])
        self.assertFalse(draft["ai_available"])
        self.assertTrue(
            all(v is None for k, v in draft["fields"].items() if k != "report_date")
        )
        self.assertIsNotNone(draft["fields"]["report_date"])

    def test_approve_unknown_site(self):
        with self.assertRaises(ValidationAppError):
            incident_report_service.approve("nope", {}, user_id="u1")

    def test_approve_persists_report_and_generates_pdf(self):
        site = self.make_site(site_name="Riverside Tower")
        assistant = self.make_assistant()
        fields = {
            "project": "Riverside Tower",
            "incident_type": "near_miss",
            "description": "Scaffolding plank slipped, no injury.",
        }
        saved = incident_report_service.approve(
            site["site_id"], fields, user_id=assistant["assistant_id"]
        )
        self.assertEqual(saved["site_id"], site["site_id"])
        self.assertEqual(saved["status"], "signed_off")
        self.assertEqual(saved["approved_by"], assistant["assistant_id"])
        self.assertEqual(saved["fields"]["project"], "Riverside Tower")
        self.assertIsNotNone(saved["pdf_path"])

        self.assertIn("job_no", saved["fields"])
        self.assertIsNone(saved["fields"]["job_no"])

    def test_approve_defaults_report_date_when_missing(self):
        site = self.make_site()
        saved = incident_report_service.approve(site["site_id"], {}, user_id=None)
        self.assertIsNotNone(saved["fields"]["report_date"])

    def test_list_incident_reports_only_returns_incidents(self):
        site = self.make_site()
        incident_report_service.approve(
            site["site_id"], {"project": "A"}, user_id=None
        )

        self.registry.reports.add(
            {
                "id": "report-other-1",
                "site_id": site["site_id"],
                "report_type": "daily",
                "status": "draft",
                "report_date": "2026-01-01",
                "approved_by": None,
                "created_at": "2026-01-01T00:00:00Z",
                "updated_at": "2026-01-01T00:00:00Z",
                "fields": {},
                "pdf_path": None,
            }
        )
        results = incident_report_service.list_incident_reports(site["site_id"])
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["fields"]["project"], "A")

    def test_get_incident_report_not_found(self):
        with self.assertRaises(ValidationAppError):
            incident_report_service.get_incident_report("nope")

    def test_delete_incident_report(self):
        site = self.make_site()
        saved = incident_report_service.approve(site["site_id"], {}, user_id=None)
        incident_report_service.delete_incident_report(saved["id"])
        with self.assertRaises(ValidationAppError):
            incident_report_service.get_incident_report(saved["id"])

    def test_delete_incident_report_not_found(self):
        with self.assertRaises(ValidationAppError):
            incident_report_service.delete_incident_report("nope")

    def test_get_pdf_bytes_returns_pdf_magic_bytes(self):
        site = self.make_site()
        saved = incident_report_service.approve(
            site["site_id"], {"project": "PDF test"}, user_id=None
        )
        pdf_bytes, report = incident_report_service.get_pdf_bytes(saved["id"])
        self.assertTrue(pdf_bytes.startswith(b"%PDF"))
        self.assertEqual(report["id"], saved["id"])

    def test_options_lists_incident_types_and_categories(self):
        options = incident_report_service.options()
        self.assertIn("accident", options["incident_types"])
        self.assertIn("near_miss", options["incident_types"])
        self.assertIn("accident", options["categories"])


globals().update(
    parametrize_over_backends(
        type("IncidentReportServiceTests", (BaseIncidentReportServiceTests,), {}),
        __name__,
    )
)


if __name__ == "__main__":
    unittest.main()
