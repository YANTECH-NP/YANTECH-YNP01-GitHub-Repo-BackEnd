# Use a minimal and secure Python image
FROM python:3.11-slim

# Set working directory in container
WORKDIR /app

# Install OS-level dependencies (if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source code
COPY admin.py .

# Optionally copy .env for local testing (ignored in AWS)
COPY .env .env

# Default command: run Flask in production mode
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5001", "admin:app"]
