FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the Whisper speech-to-text model weights at build time (needs
# internet during `docker build` only) so the container never needs network
# access at runtime. Must match STT_MODEL_SIZE in app/core/config.py.
ARG STT_MODEL_SIZE=base
RUN python -c "from faster_whisper import WhisperModel; WhisperModel('${STT_MODEL_SIZE}', device='cpu', compute_type='int8', download_root='/app/.cache/whisper')"

COPY app ./app

EXPOSE 8000

CMD ["python", "-m", "app.main"]
