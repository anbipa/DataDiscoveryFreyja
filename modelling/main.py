# main.py
from fastapi import FastAPI, Query
from pydantic import BaseModel
import joblib
import boto3
import os
import tempfile
import pandas as pd
from get_ranking_minio import get_ranking

app = FastAPI()

# Load model once at startup
model = joblib.load("/app/predictive_model.pkl")

# MinIO settings from env
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "http://minio:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin123")
BUCKET = os.getenv("MINIO_BUCKET", "data-based-data-discovery")
DISTANCES_PREFIX = "distances"

s3 = boto3.client(
    "s3",
    endpoint_url=MINIO_ENDPOINT,
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
)

@app.get("/ranking")
def get_ranking_api(dataset: str = Query(...), attribute: str = Query(...), k: int = Query(10)):
    result = get_ranking(s3, BUCKET, DISTANCES_PREFIX, dataset, attribute, k, model)
    return {"results": result}
