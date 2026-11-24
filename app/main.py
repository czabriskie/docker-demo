"""A small HTTP API that serves the iris model."""
import os
import joblib
from fastapi import FastAPI
from pydantic import BaseModel

bundle = joblib.load(os.environ.get("MODEL_PATH", "artifacts/model.joblib"))
app = FastAPI(title="Iris predictor")


class Flower(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float


def predict(f: Flower) -> dict:
    features = [[f.sepal_length, f.sepal_width, f.petal_length, f.petal_width]]
    probs = bundle["model"].predict_proba(features)[0]
    best = int(probs.argmax())
    return {"species": bundle["classes"][best], "confidence": round(float(probs[best]), 3)}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict")
def predict_endpoint(flower: Flower):
    return predict(flower)
