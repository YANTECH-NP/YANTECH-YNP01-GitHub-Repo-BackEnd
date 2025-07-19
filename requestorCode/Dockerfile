# Use a lightweight official Python base image with security patches
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the dependency file into the image
COPY requirements.txt .

# Install Python dependencies listed in requirements.txt
# --no-cache-dir ensures the image remains small by not caching wheels
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code into the container's working directory
COPY app.py .

# Set environment variable used by Flask (optional if you're running directly)
ENV FLASK_APP=app.py

# Specify the default command to run the Flask app
# --host=0.0.0.0 allows access from outside the container (ECS, Docker, etc.)
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
