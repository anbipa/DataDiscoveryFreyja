import joblib
import sklearn 
import pandas as pd
import argparse

def prepare_data_for_model(distances, model):
  distances = distances.drop(columns=['dataset_name', 'dataset_name_2', 'attribute_name', 'attribute_name_2'], axis=1) # Remove unnecesary columns
  distances = distances[model.feature_names_in_] # Arrange the columns as in the model
  distances = distances.dropna()
  return distances


def get_ranking(distances_folder_path, k, dataset, attribute, model):
  # Read distances
  distances = pd.read_csv(distances_folder_path + 'distances_' + dataset.replace(".csv", "_profile_") + attribute.replace("/", "_").replace(": ","_") + ".csv", header = 0, encoding='latin1', on_bad_lines="skip")

  dataset_names = distances["dataset_name_2"] # We store dataset and attribute names to be used to evaluate the ranking
  attribute_names = distances["attribute_name_2"]
  distances = prepare_data_for_model(distances, model) # Prepare the data

  y_pred = model.predict(distances) # Use the model to predict
  distances["predictions"] = y_pred

  distances["target_ds"] = dataset_names
  distances["target_attr"] = attribute_names

  top_k_joins = distances.sort_values(by='predictions', ascending=False).head(k)
  print(top_k_joins.head(k))

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Ranking script for joinability prediction")
  parser.add_argument("distances_folder", type=str, help="distances folder path")
  parser.add_argument("dataset", type=str, help="query dataset name")
  parser.add_argument("attribute", type=str, help="query attribute name")
  parser.add_argument("k", type=int, help="Number of top joins to return")

  args = parser.parse_args()

  model = joblib.load("/app/predictive_model.pkl")
  get_ranking(args.distances_folder, args.k, args.dataset, args.attribute, model)