# Dissertation Project

A prototype construction site assistant built for a construction company. Site assistants capture photos and voice notes on-site, and the app uses local AI models to turn the material into a generated incident report.

- **`backend/`** — Flask API (Python), handles auth, sites, pictures, voice notes, OCR, speech-to-text, and report generation
- **`frontend/`** — Flutter app

## How it works

1. An engineer photographs a site issue and/or records a voice note in the app.
2. The backend runs the photo through OCR and the voice note through a local Whisper model (`faster-whisper`) to get a transcript.
3. Local Ollama models read the pictures and transcripts and auto-fill an incident report: `llava` reads the photos, `llama3.2` turns that plus the transcripts into report fields.
4. The engineer reviews and approves the draft, then can export it as PDF or `.xlsx`.

Everything — API, database, Whisper, Ollama — runs on the same laptop, no external services needed.

## Tech stack

| Backend : Flask, SQLite, faster-whisper, Ollama (llava, llama3.2), ReportLab, openpyxl |

| Frontend : Flutter, Provider, go_router, Dio, image_picker, google_mlkit_text_recognition, speech_to_text, record |

## Getting started

You'll need:
- [Docker](https://www.docker.com/) (for the backend)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (for the frontend)
- [Ollama](https://ollama.com/) running on your machine with the `llava` and `llama3.2` models pulled, if you want AI report auto-fill to work

### 1. Run the backend

```bash
cd backend
docker compose up --build
```

This starts the API at `http://localhost:8000`.

- Data is stored in SQLite inside the `baxall_data` Docker volume, so it survives restarts.
- Browse the database directly at `http://localhost:8000/admin/`.
- Ollama is expected to be running on the host machine (`host.docker.internal:11434`), not inside the container.

**Test login:** any seeded account, password `baxall123`.

Running the backend tests:

```bash
cd backend
pip install -r requirements.txt
python run_tests.py
```

### 2. Run the frontend

```bash
cd frontend
flutter pub get
flutter run
```

By default the app points at `http://localhost:8000`. To point it at a different backend, pass:

```bash
flutter run --dart-define=API_BASE_URL=http://your-host:8000
```

### 3. Install the Android app directly

If you just want the app on a physical device without building from source, a debug APK is included at:

```
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

Sideload it onto an Android device (enable "install from unknown sources" first), or install via ADB:

```bash
adb install frontend/build/app/outputs/flutter-apk/app-debug.apk
```

## Project structure

```
backend/
  app/
    api/            # REST endpoints (auth, sites, assistants, pictures, speech, ocr, ai, reports)
    admin/           # Admin view of the DB
    core/            # Config, logging, error handling
    persistence/      # Repositories / DB access
    services/          
  tests/             # 200+ unit and integration tests

frontend/
  lib/
    features/         # auth, dashboard, camera_ocr, voice_notes, incident_reports, ai, profile, settings, shell
    core/              # config, networking, routing, theme, storage
```
