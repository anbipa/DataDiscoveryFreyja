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


java -jar "$java_jar_path" computeDistancesForBenchmark "$ground_truth" "$directory_store_profiles" "$directory_store_distances"