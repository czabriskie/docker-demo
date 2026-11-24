# ---- Stage 1: train the model inside the build ----
# Nobody needs Python on their laptop -- the build does it.
FROM python:3.12-slim AS train
WORKDIR /src
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY model/ model/
RUN MODEL_DIR=/artifacts python model/train.py

# ---- Stage 2: the small image we actually ship ----
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ app/
COPY --from=train /artifacts/model.joblib artifacts/model.joblib

# Don't run as root inside the container
RUN useradd --create-home appuser
USER appuser

EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
