# ─────────────────────────────────────────────────────────────────────────────
# Pennora Backend — Dockerfile
# Production-compatible Python image.
# Secrets are NOT baked in; supply them via environment variables at runtime.
# ─────────────────────────────────────────────────────────────────────────────

# Use a slim Debian-based Python image that supports the heavy ML libraries
# (sentence-transformers, faiss-cpu, numpy require native C extensions).
FROM python:3.11-slim

# ── Build-time system dependencies ──────────────────────────────────────────
# gcc / build-essential are needed by faiss-cpu and some sentence-transformer wheels.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        build-essential \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ── Non-root user for security ───────────────────────────────────────────────
RUN useradd --create-home --shell /bin/bash appuser

# ── Working directory ────────────────────────────────────────────────────────
WORKDIR /app

# ── Install Python dependencies first (layer-cached) ────────────────────────
# Copy requirements BEFORE the rest of the code so Docker cache is preserved
# when only source code changes.
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ── Copy application source (secrets excluded via .dockerignore) ─────────────
COPY . .

# ── Transfer ownership to non-root user ─────────────────────────────────────
RUN chown -R appuser:appuser /app

USER appuser

# ── Runtime configuration ────────────────────────────────────────────────────
# PORT defaults to 8000; override via -e PORT=<n> at docker run time.
ENV PORT=8000 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE ${PORT}

# ── Healthcheck ──────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:${PORT}/health || exit 1

# ── Entrypoint ───────────────────────────────────────────────────────────────
# Use shell form so ${PORT} is expanded at runtime.
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
