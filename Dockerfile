# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# system deps (if needed)
RUN apt-get update && apt-get install -y build-essential gcc libpq-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*

# copy and install deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# copy app
COPY ./app ./app

ENV PORT=8000
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
