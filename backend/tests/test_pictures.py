import io
import unittest

from tests import support
from tests.support import parametrize_over_backends

from app.core.exceptions import NotFoundError, ValidationAppError
from app.services import picture_service


class BasePictureServiceTests:
    def test_save_picture_requires_file_path(self):
        site = self.make_site()
        with self.assertRaises(ValidationAppError):
            picture_service.save_picture(site["site_id"], file_path="")

    def test_save_picture_unknown_site(self):
        with self.assertRaises(ValidationAppError):
            picture_service.save_picture("nope", file_path="pictures/x.jpg")

    def test_save_and_list_pictures(self):
        site = self.make_site()
        picture_service.save_picture(
            site["site_id"], file_path="pictures/a.jpg", caption="  Trench edge  "
        )
        pictures = picture_service.list_pictures(site["site_id"])
        self.assertEqual(len(pictures), 1)

        self.assertEqual(pictures[0]["caption"], "Trench edge")

    def test_delete_picture_not_found(self):
        with self.assertRaises(NotFoundError):
            picture_service.delete_picture("nope")

    def test_delete_picture(self):
        site = self.make_site()
        record = picture_service.save_picture(site["site_id"], file_path="pictures/a.jpg")
        picture_service.delete_picture(record["id"])
        self.assertEqual(picture_service.list_pictures(site["site_id"]), [])


globals().update(
    parametrize_over_backends(
        type("PictureServiceTests", (BasePictureServiceTests,), {}), __name__
    )
)


class BasePictureApiTests:
    """Combined with RepositoryBackedTestCase (has self.registry/make_*) and
    provides a Flask test client, mirroring tests/test_api.py's pattern."""

    def setUp(self):
        super().setUp()
        import app.main as app_main

        self.client = app_main.app.test_client()

    def login(self, email: str, password: str) -> str:
        resp = self.client.post(
            "/api/v1/auth/login", json={"email": email, "password": password}
        )
        return resp.get_json()["access_token"]

    def auth_headers(self, token: str) -> dict:
        return {"Authorization": f"Bearer {token}"}

    def test_upload_picture_requires_site_id(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.post(
            "/api/v1/pictures",
            data={"file": (io.BytesIO(b"fake-bytes"), "photo.jpg")},
            content_type="multipart/form-data",
            headers=self.auth_headers(token),
        )
        self.assertEqual(resp.status_code, 422)

    def test_upload_list_delete_picture(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")

        upload_resp = self.client.post(
            "/api/v1/pictures",
            data={
                "file": (io.BytesIO(b"fake-bytes"), "photo.jpg"),
                "site_id": site["site_id"],
                "caption": "Test photo",
            },
            content_type="multipart/form-data",
            headers=self.auth_headers(token),
        )
        self.assertEqual(upload_resp.status_code, 200)
        picture = upload_resp.get_json()
        self.assertEqual(picture["caption"], "Test photo")

        list_resp = self.client.get(
            f"/api/v1/pictures?site_id={site['site_id']}",
            headers=self.auth_headers(token),
        )
        self.assertEqual(list_resp.status_code, 200)
        self.assertEqual(len(list_resp.get_json()), 1)

        delete_resp = self.client.delete(
            f"/api/v1/pictures/{picture['id']}", headers=self.auth_headers(token)
        )
        self.assertEqual(delete_resp.status_code, 200)
        self.assertTrue(delete_resp.get_json()["deleted"])


globals().update(
    parametrize_over_backends(
        type("PictureApiTests", (BasePictureApiTests,), {}), __name__
    )
)


if __name__ == "__main__":
    unittest.main()
