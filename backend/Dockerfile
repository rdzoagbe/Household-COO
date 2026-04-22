FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir \
    --extra-index-url https://pypi.emergentmethods.ai/simple/ \
    -r requirements.txt

COPY . .

CMD uvicorn server:app --host 0.0.0.0 --port ${PORT:-8000}
