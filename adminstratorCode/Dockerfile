FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY admin.py .
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5001", "admin:app"]
