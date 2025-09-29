FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY server/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY server/app ./server/app
COPY scripts ./scripts

EXPOSE 8000

CMD ["uvicorn", "server.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
