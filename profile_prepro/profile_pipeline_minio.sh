#!/bin/bash

# Define temp directories
temp_dir="/tmp/preprocessing"
mkdir -p "$temp_dir/benchmark" "$temp_dir/profiles" "$temp_dir/output"

# MinIO alias config
mc alias set minio http://minio:9000 minioadmin minioadmin123

# Download benchmark CSVs from MinIO
mc ls minio/data-based-data-discovery/benchmark/ | awk '{print $NF}' | while read -r filename; do
    echo "Downloading $filename from MinIO"
    mc cp "minio/data-based-data-discovery/benchmark/$filename" "$temp_dir/benchmark/"
done

# Set internal directories to local temp
directory_benchmark="$temp_dir/benchmark"
directory_store_profiles="$temp_dir/profiles"
directory_store_distances="$temp_dir/output"

java_jar_path="/app/DataDiscovery-all.jar"

# Get list of files in benchmark directory
files=()
while IFS= read -r file; do
    files+=("$file")
done < <(find "$directory_benchmark" -maxdepth 1 -type f)

# Max number of concurrent jobs
MAX_THREADS=8

# Function to run profile creation
create_profile() {
    local file="$1"
    local out_dir="$2"
    java -jar "$java_jar_path" createProfile "$file" "$out_dir"
}

# Measure execution time
start_time=$(date +%s)

# Process files in parallel
for ((i = 0; i < ${#files[@]}; i++)); do
    while [ "$(jobs -r | wc -l)" -ge "$MAX_THREADS" ]; do
        sleep 0.1
    done
    echo "Processing file $((i+1)) / ${#files[@]}: ${files[$i]}"
    create_profile "${files[$i]}" "$directory_store_profiles" &
done

# Wait for all background jobs to finish
wait

end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Loop execution time: $elapsed seconds"

#!/bin/bash

# Loop over all attributes in all profile files
for query_file in "$directory_store_profiles"/*.csv; do
    while IFS= read -r line; do
        # Skip the header
        if [[ "$line" == "val_pct_std"* ]]; then
            continue
        fi
        # Extract attribute name and dataset name
        dataset_name=$(echo "$line" | awk -F';' '{print $(NF-12)}')
        attribute_name=$(echo "$line" | awk -F';' '{print $(NF-25)}' | tr -d '"')

        echo "Computing distances for: $dataset_name - $attribute_name"
        java -jar "$java_jar_path" computeDistances "$dataset_name" "$attribute_name" "$directory_store_profiles" "$directory_store_distances"
    done < "$query_file"
done

mc mb minio/data-based-data-discovery/profiles
mc mb minio/data-based-data-discovery/distances


# Upload profiles and distances back to MinIO
mc cp "$directory_store_profiles"/*.csv minio/data-based-data-discovery/profiles/
mc cp "$directory_store_distances"/distances/*.csv minio/data-based-data-discovery/distances/



#java -jar "$java_jar_path" computeDistances "dataset_name" "dataset_query_attr" "$directory_store_profiles" "$directory_store_distances"