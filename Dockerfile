# Build stage
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY TaskManager/requirements.txt .

RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# Copy only the installed Python packages from builder
COPY --from=builder /root/.local /root/.local

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_APP=TaskManager/app.py \
    FLASK_ENV=production \
    DATABASE=/app/instance/task_manager.sqlite \
    PATH="/root/.local/bin:$PATH"
# ENV SECRET_KEY is intentionally not set here for security.

COPY . .

RUN mkdir -p /app/instance && \
    chmod -R 777 /app/instance

USER nobody

EXPOSE 5000

CMD ["sh", "-c", "mkdir -p /app/instance && touch /app/instance/task_manager.sqlite && chmod -R 777 /app/instance && gunicorn --bind 0.0.0.0:5000 --workers 4 --threads 2 TaskManager.app:app"]
