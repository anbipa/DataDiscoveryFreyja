import joblib
import sklearn 
import pandas as pd
import argparse
import boto3
import os
import tempfile

def prepare_data_for_model(distances, model):
  distances = distances.drop(columns=['dataset_name', 'dataset_name_2', 'attribute_name', 'attribute_name_2'], axis=1) # Remove unnecesary columns
  distances = distances[model.feature_names_in_] # Arrange the columns as in the model
  distances = distances.dropna()
  return distances

def download_from_minio(s3, bucket, object_key, local_path):
  s3.download_file(bucket, object_key, local_path)



def get_ranking(s3, bucket, distances_prefix, dataset, attribute, k, model):
  # Construct file name
  fname = f"distances_{dataset.replace('.csv', '_profile_')}{attribute.replace('/', '_').replace(': ', '_')}.csv"
  object_key = f"{distances_prefix}/{fname}"

  with tempfile.TemporaryDirectory() as tmpdir:
    local_path = os.path.join(tmpdir, fname)
    print(f"Downloading {object_key} from MinIO...")
    download_from_minio(s3, bucket, object_key, local_path)

    distances = pd.read_csv(local_path, encoding='latin1', on_bad_lines='skip')

    dataset_names = distances["dataset_name_2"]
    attribute_names = distances["attribute_name_2"]

    distances = prepare_data_for_model(distances, model)
    #distances["predictions"] = model.predict(distances)
    preds = model.predict(distances)
    if preds.max() == 0:
      distances["predictions"] = 0.0
    else:
      distances["predictions"] = preds / preds.max()

    distances["target_ds"] = dataset_names
    distances["target_attr"] = attribute_names

    pd.set_option("display.max_columns", None)
    pd.set_option("display.max_rows", None)
    pd.set_option("display.max_colwidth", None)
    pd.set_option("display.expand_frame_repr", False)

    top_k_joins = distances.sort_values(by="predictions", ascending=False).head(k)
    print("Top-K Results:")
    top_k_joins = top_k_joins.reset_index(drop=True)
    top_k_joins.index += 1  # Make index start at 1
    print(top_k_joins[["predictions", "target_ds", "target_attr"]])



# (Optional) Upload results back to MinIO
    #result_path = os.path.join(tmpdir, f"ranking_{dataset}_{attribute}.csv")
    #top_k_joins.to_csv(result_path, index=False)

    #s3.upload_file(result_path, bucket, f"results/ranking_{dataset}_{attribute}.csv")
    #print(f"Uploaded results to: results/ranking_{dataset}_{attribute}.csv")

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Ranking script for joinability prediction")
  parser.add_argument("dataset", type=str, help="query dataset name")
  parser.add_argument("attribute", type=str, help="query attribute name")
  parser.add_argument("k", type=int, help="Number of top joins to return")

  args = parser.parse_args()

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

  model = joblib.load("/app/predictive_model.pkl")
  get_ranking(s3, BUCKET, DISTANCES_PREFIX, args.dataset, args.attribute, args.k, model)