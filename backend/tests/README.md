# Backend tests

Unit test-based for the backend.

## Running the tests

```bash
cd backend
pip install -r requirements.txt
python run_tests.py
python run_tests.py -v
python run_tests.py tests.test_api
r```

## What was tested

| File | Covers |
|---|---|
| `test_security.py` | Password verification |
| `test_persistence.py` | CRUD for every repository (assistants, sites, reports, pictures, voice notes) |
| `test_services.py` | auth_service, assistant_service, site_service logic |
| `test_incident_report_service.py` | Incident report draft → approve → list → PDF → delete flow |
| `test_incident_report_export.py` | The .xlsx export against the real official template |
| `test_pictures.py` | picture_service + the /pictures upload/list/delete API |
| `test_speech.py` | Voice-note, the /speech API, and transcribe() with the Whisper model mocked out |
| `test_ocr_and_ai.py` | The mocked OCR and AI-suggestion services |
| `test_api.py` | End-to-end HTTP tests via Flask's test client: auth, sites, assistants, profile, incident reports, error handling |

206 tests total.


## Test isolation

- Every test gets a fresh registry — an empty in-memory dict, or a brand temp SQLite file — so there's no shared state or ordering dependencies between tests.
- UPLOAD_DIR points at a temp directory for the whole run. The OS cleans it up eventually, or call tests.support.cleanup_upload_dir() yourself if you want it gone right away.
- AI_AUTOFILL_ENABLED, MOCK_OCR_DELAY, and MOCK_AI_DELAY are all overridden in the test environment so the suite runs in seconds instead of the ~3s/request it'd take with the real prototype delays.