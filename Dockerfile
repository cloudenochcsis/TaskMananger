# Build stage
FROM python:3.9-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY TaskManager/requirements.txt .

# Install Python dependencies
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.9-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=TaskManager/app.py
ENV FLASK_ENV=production
ENV DATABASE=/app/instance/task_manager.sqlite
# ENV SECRET_KEY is intentionally not set here for security. Set it at runtime via your deployment platform.
ENV PATH="/home/appuser/.local/bin:$PATH"

# Set the working directory in the container
WORKDIR /app

# Install system dependencies and Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev sqlite3 && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user if it doesn't exist
RUN if ! getent group appuser >/dev/null; then groupadd -r appuser; fi && \
    if ! getent passwd appuser >/dev/null; then useradd -r -g appuser appuser; fi

# Copy requirements file
COPY TaskManager/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir gunicorn==23.0.0

# No initialization script needed - handled in CMD

# Copy the rest of the application
COPY . .

# Create and set permissions for instance directory
RUN mkdir -p /app/instance && \
    chown -R appuser:appuser /app && \
    chmod -R 777 /app/instance

# Switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["sh", "-c", "mkdir -p /app/instance && touch /app/instance/task_manager.sqlite && chmod -R 777 /app/instance && chown -R appuser:appuser /app/instance && echo 'DROP TABLE IF EXISTS users; DROP TABLE IF EXISTS tasks; CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, password TEXT NOT NULL); CREATE TABLE tasks (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT, status TEXT NOT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, created_by INTEGER NOT NULL, assigned_to INTEGER NOT NULL, FOREIGN KEY (created_by) REFERENCES users (id), FOREIGN KEY (assigned_to) REFERENCES users (id));' | sqlite3 /app/instance/task_manager.sqlite && gunicorn --bind 0.0.0.0:5000 --workers 4 --threads 2 TaskManager.app:app"]
