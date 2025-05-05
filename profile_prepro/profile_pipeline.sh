#!/bin/bash

# Set directories
#directory_benchmark="/Users/anbipa/Desktop/DTIM/Cyclops/datalake"
#directory_store_profiles="/Users/anbipa/Desktop/DTIM/Cyclops/profiles"
#directory_store_distances="/Users/anbipa/Desktop/DTIM/Cyclops"
#ground_truth="/Users/anbipa/Desktop/DTIM/Cyclops/DataDiscovery/ground_truths/freyja_ground_truth.csv"
#java_jar_path="/Users/anbipa/Desktop/DTIM/Cyclops/DataDiscovery/build/libs/DataDiscovery-all.jar"

# External mount paths
directory_benchmark="/benchmark"
directory_store_profiles="/profiles"
directory_store_distances="/output"
ground_truth="/ground_truths/freyja_ground_truth.csv"
java_jar_path="/app/DataDiscovery-all.jar"

# Create directory to store profiles if it doesn't exist
if [ ! -d "$directory_store_profiles" ]; then
    mkdir -p "$directory_store_profiles"
    echo "Directory created: $directory_store_profiles"
fi

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


#java -jar "$java_jar_path" computeDistances "dataset_name" "dataset_query_attr" "$directory_store_profiles" "$directory_store_distances"