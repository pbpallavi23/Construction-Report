import tempfile
import unittest
from unittest.mock import MagicMock, patch

from tests import support

from app.core.config import settings
from app.services import ai_service, ocr_service


def _fake_response(json_body: dict, ok: bool = True) -> MagicMock:
    """A minimal stand-in for requests.Response, shaped the way Ollama's
    /api/generate replies: {"response": "<json-encoded string>"}."""
    import json as _json

    resp = MagicMock()
    resp.ok = ok
    resp.raise_for_status = MagicMock() if ok else MagicMock(
        side_effect=Exception("HTTP error")
    )
    resp.json.return_value = {"response": _json.dumps(json_body)}
    return resp


def _write_temp_file(data: bytes) -> str:
    fd, path = tempfile.mkstemp(dir=settings.UPLOAD_DIR)
    with open(fd, "wb") as f:
        f.write(data)
    return path


class OcrServiceTests(unittest.TestCase):
    """extract_text() calls a local Ollama vision model. No Ollama server
    runs in the test environment, so the "no mock" tests exercise the real
    failure-handling path; the mocked tests exercise the parsing logic
    without needing Ollama actually running."""

    def test_extract_text_with_no_file_returns_empty_result(self):
        result = ocr_service.extract_text(None)
        self.assertEqual(result["document_type"], "Unknown")
        self.assertEqual(result["raw_text"], "")
        self.assertEqual(result["fields"], [])
        self.assertEqual(result["confidence"], 0.0)
        self.assertIn("processing_ms", result)

    def test_extract_text_falls_back_when_ollama_is_unreachable(self):
        # No Ollama server is running in this environment, so the request
        # itself fails and extract_text should degrade gracefully rather
        # than raising - regardless of whether the file exists.
        result = ocr_service.extract_text("nonexistent/scan.jpg")
        self.assertEqual(result["document_type"], "Unknown")
        self.assertIsInstance(result["fields"], list)
        self.assertTrue(0 <= result["confidence"] <= 1)

    @patch("app.services.ocr_service.requests.post")
    @patch("app.services.ocr_service.absolute_path")
    def test_extract_text_parses_a_successful_ollama_response(
        self, mock_abs_path, mock_post
    ):
        mock_abs_path.return_value = _write_temp_file(b"\x00fake-image-bytes")
        mock_post.return_value = _fake_response({
            "document_type": "Delivery Note",
            "raw_text": "CONSTRUCTION MATERIALS DELIVERY NOTE\nSupplier: BUILD-ALL INC.",
            "fields": [
                {"label": "Document Type", "value": "Delivery Note"},
                {"label": "Supplier", "value": "BUILD-ALL INC."},
                {"label": "Ignored - missing value", "value": ""},
            ],
        })

        result = ocr_service.extract_text("scan.jpg")

        self.assertEqual(result["document_type"], "Delivery Note")
        self.assertIn("BUILD-ALL INC.", result["raw_text"])
        self.assertEqual(len(result["fields"]), 2)  # the empty-value field is dropped
        self.assertEqual(result["fields"][1], {"label": "Supplier", "value": "BUILD-ALL INC."})
        self.assertGreater(result["confidence"], 0)

    @patch("app.services.ocr_service.requests.post")
    @patch("app.services.ocr_service.absolute_path")
    def test_extract_text_handles_malformed_json_gracefully(
        self, mock_abs_path, mock_post
    ):
        mock_abs_path.return_value = _write_temp_file(b"\x00fake-image-bytes")
        bad_response = MagicMock()
        bad_response.ok = True
        bad_response.raise_for_status = MagicMock()
        bad_response.json.return_value = {"response": "not valid json"}
        mock_post.return_value = bad_response

        result = ocr_service.extract_text("scan.jpg")

        self.assertEqual(result["document_type"], "Unknown")
        self.assertEqual(result["fields"], [])


class AiSuggestServiceTests(unittest.TestCase):
    """suggest() calls a local Ollama text model, optionally grounded in a
    site's recent voice notes. AI_AUTOFILL_ENABLED is false in the test
    environment (see tests/support.py), so ollama_available() is always
    False here unless a test explicitly overrides it."""

    def test_suggest_returns_no_suggestions_when_ai_disabled(self):
        result = ai_service.suggest("daily_report")
        self.assertEqual(result["suggestions"], [])
        self.assertIn("processing_ms", result)

    def test_suggest_unknown_context_does_not_raise(self):
        # Falls back to the daily_report label internally; still returns
        # the same empty-suggestions shape while AI is disabled.
        result = ai_service.suggest("not-a-real-context")
        self.assertEqual(result["suggestions"], [])

    @patch("app.services.ai_service.requests.post")
    @patch("app.services.ai_service.ollama_available", return_value=True)
    def test_suggest_parses_a_successful_ollama_response(
        self, mock_available, mock_post
    ):
        mock_post.return_value = _fake_response({
            "suggestions": [
                {"title": "Work completed summary", "text": "Steelwork progressed on the east elevation.", "confidence": 0.8},
                {"title": "Missing text is dropped", "confidence": 0.9},
                {"title": "Bad confidence clamped", "text": "Some text.", "confidence": 5},
            ]
        })

        result = ai_service.suggest("daily_report", prompt="check the scaffolding")

        self.assertEqual(len(result["suggestions"]), 2)  # the missing-text entry is dropped
        self.assertEqual(result["suggestions"][0]["title"], "Work completed summary")
        self.assertEqual(result["suggestions"][1]["confidence"], 1.0)  # clamped to [0, 1]
        mock_post.assert_called_once()
        sent_prompt = mock_post.call_args.kwargs["json"]["prompt"]
        self.assertIn("check the scaffolding", sent_prompt)

    @patch("app.services.ai_service.requests.post")
    @patch("app.services.ai_service.ollama_available", return_value=True)
    def test_suggest_handles_ollama_failure_gracefully(
        self, mock_available, mock_post
    ):
        import requests as requests_module
        mock_post.side_effect = requests_module.ConnectionError("connection refused")
        result = ai_service.suggest("safety")
        self.assertEqual(result["suggestions"], [])


if __name__ == "__main__":
    unittest.main()