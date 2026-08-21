import unittest

from tests import support
from tests.support import RepositoryBackedTestCase, parametrize_over_backends

import app.main as app_main


class BaseApiTests:
    """Mixin of API tests. Combined with RepositoryBackedTestCase by
    `parametrize_over_backends` below. Uses a single shared Flask app
    (created once at import time) with a fresh Flask test client per test;
    the persistence registry is still swapped per test via setUp, so every
    test starts from an empty, isolated data set regardless of backend.
    """

    def setUp(self):
        super().setUp()
        self.client = app_main.app.test_client()



    def login(self, email: str, password: str) -> str:
        resp = self.client.post(
            "/api/v1/auth/login", json={"email": email, "password": password}
        )
        self.assertEqual(resp.status_code, 200, resp.get_json())
        return resp.get_json()["access_token"]

    def auth_headers(self, token: str) -> dict:
        return {"Authorization": f"Bearer {token}"}



    def test_health_endpoint(self):
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["status"], "ok")



    def test_login_success(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        resp = self.client.post(
            "/api/v1/auth/login",
            json={"email": "j.smith@baxall.co.uk", "password": "baxall123"},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertIn("access_token", data)

        self.assertNotIn("password_hash", data["assistant"])

    def test_login_wrong_password(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        resp = self.client.post(
            "/api/v1/auth/login",
            json={"email": "j.smith@baxall.co.uk", "password": "wrong"},
        )
        self.assertEqual(resp.status_code, 401)
        self.assertEqual(resp.get_json()["error"]["code"], "unauthorized")

    def test_login_missing_fields(self):
        resp = self.client.post("/api/v1/auth/login", json={"email": "a@b.com"})
        self.assertEqual(resp.status_code, 422)
        self.assertEqual(resp.get_json()["error"]["code"], "validation_error")

    def test_protected_route_without_token(self):
        resp = self.client.get("/api/v1/auth/me")
        self.assertEqual(resp.status_code, 401)

    def test_protected_route_with_malformed_header(self):
        resp = self.client.get(
            "/api/v1/auth/me", headers={"Authorization": "NotBearer xyz"}
        )
        self.assertEqual(resp.status_code, 401)

    def test_protected_route_with_invalid_token(self):
        resp = self.client.get(
            "/api/v1/auth/me", headers={"Authorization": "Bearer garbage.token.here"}
        )
        self.assertEqual(resp.status_code, 401)

    def test_auth_me_with_valid_token(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get("/api/v1/auth/me", headers=self.auth_headers(token))
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["email"], "j.smith@baxall.co.uk")

    def test_auth_logout(self):
        self.make_assistant(email="j.smith@baxall.co.uk", password="baxall123")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.post(
            "/api/v1/auth/logout", headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 200)



    def test_list_sites_requires_auth(self):
        resp = self.client.get("/api/v1/sites")
        self.assertEqual(resp.status_code, 401)

    def test_list_sites(self):
        assistant = self.make_assistant(email="j.smith@baxall.co.uk")
        self.make_site(site_name="Tower A", assigned_assistant_id=None)
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get("/api/v1/sites", headers=self.auth_headers(token))
        self.assertEqual(resp.status_code, 200)
        names = {s["site_name"] for s in resp.get_json()}
        self.assertIn("Tower A", names)

    def test_get_site_not_found(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get(
            "/api/v1/sites/nope", headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 404)
        self.assertEqual(resp.get_json()["error"]["code"], "not_found")

    def test_update_site(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.patch(
            f"/api/v1/sites/{site['site_id']}",
            json={"phase": "Groundworks"},
            headers=self.auth_headers(token),
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["phase"], "Groundworks")



    def test_get_profile(self):
        self.make_assistant(email="j.smith@baxall.co.uk", full_name="Jamie Smith")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get(
            "/api/v1/profile", headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["full_name"], "Jamie Smith")

    def test_update_profile(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.patch(
            "/api/v1/profile",
            json={"full_name": "New Name"},
            headers=self.auth_headers(token),
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["full_name"], "New Name")

    def test_list_assistants_requires_auth(self):
        resp = self.client.get("/api/v1/assistants")
        self.assertEqual(resp.status_code, 401)

    def test_get_assistant_not_found(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get(
            "/api/v1/assistants/nope", headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 404)



    def test_incident_report_options(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.get(
            "/api/v1/reports/incident/options", headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 200)
        self.assertIn("incident_types", resp.get_json())

    def test_generate_and_approve_incident_report(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")

        gen_resp = self.client.post(
            "/api/v1/reports/incident/generate",
            json={"site_id": site["site_id"]},
            headers=self.auth_headers(token),
        )
        self.assertEqual(gen_resp.status_code, 200)
        self.assertFalse(gen_resp.get_json()["ai_available"])

        approve_resp = self.client.post(
            "/api/v1/reports/incident/approve",
            json={"site_id": site["site_id"], "fields": {"project": "Test"}},
            headers=self.auth_headers(token),
        )
        self.assertEqual(approve_resp.status_code, 200)
        report = approve_resp.get_json()
        self.assertEqual(report["fields"]["project"], "Test")

        list_resp = self.client.get(
            f"/api/v1/reports/incident?site_id={site['site_id']}",
            headers=self.auth_headers(token),
        )
        self.assertEqual(list_resp.status_code, 200)
        self.assertEqual(len(list_resp.get_json()), 1)

        pdf_resp = self.client.get(
            f"/api/v1/reports/incident/{report['id']}/pdf",
            headers=self.auth_headers(token),
        )
        self.assertEqual(pdf_resp.status_code, 200)
        self.assertEqual(pdf_resp.mimetype, "application/pdf")

    def test_incident_report_export_xlsx(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")

        approve_resp = self.client.post(
            "/api/v1/reports/incident/approve",
            json={"site_id": site["site_id"], "fields": {"project": "Test"}},
            headers=self.auth_headers(token),
        )
        report_id = approve_resp.get_json()["id"]

        export_resp = self.client.get(
            f"/api/v1/reports/incident/{report_id}/export",
            headers=self.auth_headers(token),
        )
        self.assertEqual(export_resp.status_code, 200)
        self.assertIn("spreadsheetml", export_resp.mimetype)

    def test_ocr_scan_without_site(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.post(
            "/api/v1/ocr/scan", data={}, headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 200)
        self.assertIn("document_type", resp.get_json())

    def test_ai_suggestions(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.post(
            "/api/v1/ai/suggestions",
            json={"context": "safety"},
            headers=self.auth_headers(token),
        )
        self.assertEqual(resp.status_code, 200)
        self.assertIn("suggestions", resp.get_json())



    def test_unknown_route_returns_404_json(self):
        resp = self.client.get("/api/v1/does-not-exist")
        self.assertEqual(resp.status_code, 404)
        self.assertEqual(resp.get_json()["error"]["code"], "not_found")


globals().update(
    parametrize_over_backends(
        type("ApiTests", (BaseApiTests,), {}),
        __name__,
    )
)


if __name__ == "__main__":
    unittest.main()
