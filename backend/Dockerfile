FROM python:3.11-slim
# This sets the folder INSIDE the container
WORKDIR /app
# This copies everything from your backend folder INTO the container
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
# This starts the server looking at server.py in the current folder (/app)
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]