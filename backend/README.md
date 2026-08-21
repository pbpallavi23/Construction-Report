# Baxall Site Assistant — Backend API

Flask backend for the Baxall Construction Site Assistant prototype, covering the two core entities (assistant and site) along with the feature data on top: reports, pictures and voice notes.

Reports are generated from the actual pictures and voice notes saved to a site, and the data can be viewed  at http://localhost:8000/admin/. 
Speech-to-text runs on a local Whisper model via faster-whisper. Report auto-fill runs on local Ollama models — llava for reading the site photos, llama3.2 for turning that plus the voice note transcripts into the report fields.

## Quick start (Docker)

```bash
cd backend
docker compose up --build
```

That spins up one API service on localhost:8000.
- SQLite data lives in the `baxall_data` Docker volume, so it survives
  restarts.
- You can browse the database directly at http://localhost:8000/admin/.


## Login for testing

Password is the same for every seeded account: `baxall123`