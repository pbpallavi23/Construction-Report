import io
import unittest
from unittest.mock import MagicMock, patch

from tests import support
from tests.support import parametrize_over_backends

from app.core.exceptions import NotFoundError, ValidationAppError
from app.services import speech_service


class BaseSpeechNotesServiceTests:
    """Voice-note CRUD only - `transcribe()` needs faster-whisper and is
    covered separately with the model mocked out (see
    TranscribeServiceTests below), so it doesn't require the real model
    weights to be downloaded just to run the test suite.
    """

    def test_save_note_unknown_site(self):
        with self.assertRaises(ValidationAppError):
            speech_service.save_note("nope", transcript="hello")

    def test_save_and_list_notes(self):
        site = self.make_site()
        speech_service.save_note(site["site_id"], transcript="Poured concrete.")
        notes = speech_service.list_notes(site["site_id"])
        self.assertEqual(len(notes), 1)
        self.assertEqual(notes[0]["transcript"], "Poured concrete.")

    def test_delete_note_not_found(self):
        with self.assertRaises(NotFoundError):
            speech_service.delete_note("nope")

    def test_delete_note(self):
        site = self.make_site()
        note = speech_service.save_note(site["site_id"], transcript="Test note")
        speech_service.delete_note(note["id"])
        self.assertEqual(speech_service.list_notes(site["site_id"]), [])


globals().update(
    parametrize_over_backends(
        type("SpeechNotesServiceTests", (BaseSpeechNotesServiceTests,), {}), __name__
    )
)


class TranscribeServiceTests(unittest.TestCase):
    """`speech_service.transcribe` lazily imports faster_whisper inside
    `_model()`, so the real (heavy) model is mocked out here rather than
    installed - these tests check the surrounding logic (confidence
    calculation, empty-speech handling, missing-audio handling), not
    Whisper itself.
    """

    def _fake_segment(self, text, start, end, avg_logprob):
        seg = MagicMock()
        seg.text = text
        seg.start = start
        seg.end = end
        seg.avg_logprob = avg_logprob
        return seg

    def test_transcribe_no_audio_raises(self):
        with self.assertRaises(ValidationAppError):
            speech_service.transcribe(None)

    def test_transcribe_success_computes_confidence_and_joins_segments(self):
        segments = [
            self._fake_segment(" Poured concrete ", 0.0, 2.0, -0.1),
            self._fake_segment(" to section 4A. ", 2.0, 4.0, -0.2),
        ]
        info = MagicMock()
        info.duration = 4.0

        fake_model = MagicMock()
        fake_model.transcribe.return_value = (iter(segments), info)

        with patch.object(speech_service, "_model", return_value=fake_model):
            result = speech_service.transcribe(io.BytesIO(b"fake-audio"))

        self.assertEqual(result["transcript"], "Poured concrete to section 4A.")
        self.assertTrue(0.0 < result["confidence"] <= 1.0)
        self.assertEqual(result["duration_seconds"], 4)

    def test_transcribe_uses_provided_duration_override(self):
        segments = [self._fake_segment("Hello", 0.0, 1.0, -0.05)]
        info = MagicMock()
        info.duration = 1.0
        fake_model = MagicMock()
        fake_model.transcribe.return_value = (iter(segments), info)

        with patch.object(speech_service, "_model", return_value=fake_model):
            result = speech_service.transcribe(
                io.BytesIO(b"fake-audio"), duration_seconds=99
            )
        self.assertEqual(result["duration_seconds"], 99)

    def test_transcribe_no_speech_detected_raises(self):
        info = MagicMock()
        info.duration = 3.0
        fake_model = MagicMock()
        fake_model.transcribe.return_value = (iter([]), info)

        with patch.object(speech_service, "_model", return_value=fake_model):
            with self.assertRaises(ValidationAppError):
                speech_service.transcribe(io.BytesIO(b"fake-audio"))


class BaseSpeechApiTests:
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

    def test_save_note_json_body(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")

        resp = self.client.post(
            "/api/v1/speech/notes",
            json={"site_id": site["site_id"], "transcript": "Test transcript"},
            headers=self.auth_headers(token),
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["transcript"], "Test transcript")

    def test_save_note_missing_fields(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        token = self.login("j.smith@baxall.co.uk", "baxall123")
        resp = self.client.post(
            "/api/v1/speech/notes", json={}, headers=self.auth_headers(token)
        )
        self.assertEqual(resp.status_code, 422)

    def test_list_and_delete_notes(self):
        self.make_assistant(email="j.smith@baxall.co.uk")
        site = self.make_site()
        token = self.login("j.smith@baxall.co.uk", "baxall123")

        save_resp = self.client.post(
            "/api/v1/speech/notes",
            json={"site_id": site["site_id"], "transcript": "Note A"},
            headers=self.auth_headers(token),
        )
        note_id = save_resp.get_json()["id"]

        list_resp = self.client.get(
            f"/api/v1/speech/notes?site_id={site['site_id']}",
            headers=self.auth_headers(token),
        )
        self.assertEqual(len(list_resp.get_json()), 1)

        delete_resp = self.client.delete(
            f"/api/v1/speech/notes/{note_id}", headers=self.auth_headers(token)
        )
        self.assertEqual(delete_resp.status_code, 200)


globals().update(
    parametrize_over_backends(
        type("SpeechApiTests", (BaseSpeechApiTests,), {}), __name__
    )
)


if __name__ == "__main__":
    unittest.main()
