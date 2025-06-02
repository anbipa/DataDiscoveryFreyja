# DataDiscovery component
 
## Introduction
This is a tool used to perform data discovery in large-scale environments such as data lakes. The goal of this project is to provide an easy-to-use and lightweight approach for data discovery, that considerably reduces the time requirements of data discovery tasks whilst keeping a high accuracy in the detection of relevant data.

## Deployment Requirements
### Enviroment Variables
If a MinIO server is running, the following environment variables need to be set:
- **MINIO_ENDPOINT**: The endpoint of the MinIO server (e.g., `http://minio:9000`).
- **MINIO_ACCESS_KEY**: The access key for the MinIO server (e.g., `minioadmin`).
- **MINIO_SECRET_KEY**: The secret key for the MinIO server (e.g., `minioadmin123`).
- **MINIO_BUCKET**: The name of the bucket to be used (e.g., `data-based-data-discovery`).
- **MINIO_FOLDER_BENCHMARK**: The folder within the bucket where benchmark data is stored (e.g., `benchmark`).

### Volumes & Persistent Storage
This tool supports two modes of file access:
(1) local volumes using Docker bind mounts, and
(2) external storage access via MinIO (LTS).
#### Option 1: Using Docker Volumes (Local)
The tool uses docker [bind mounts](https://docs.docker.com/engine/storage/bind-mounts/) to allow users to provide their input files and access outputs.
- **Input Volumes**:
  1. The benchmark input volume is mounted to the container's `/app/benchmark` directory. Users can place their input files in this directory.
- **Output Volume**: The output volume is mounted to the container's `/app/outputs` directory. The application will save its output files in this directory.
#### Option 2: Using MinIO (LTS Integration)
The tool also supports integration with Cyclops' Long-Term Storage (LTS) via a MinIO-compatible API. This mode does not require local mounts and supports fully remote workflows.

### Network Configuration
- In MinIO mode, the container must be connected to the Docker network that includes the MinIO instance (e.g., long-term-storage_default).


## Infrastructure Setup & Resource Allocation
### CPU & Memory Requirements
CPU usage is high, but can increase/decrease depending on the benchmark size.

### Storage Considerations
- Disk space:
    - Base image size: ~ 350 MB
### External Service Dependencies
- Future: LTS and IKB services for data retrieval and annotation.

### Service Scaling & Load
- The application is designed to run on a single instance. However, the component is stateless and can be horizontally scaled where applicable (e.g., for several benchmarks).

## Security & Access Credentials
### Authentication & Authorization
- The application does not require authentication or authorization mechanisms in this version.
### TLS/SSL Requirements
- The application does not require TLS/SSL in this version.

## Repository Structure
```bash
├── ground_truths
├── modelling
│   ├── Dockerfile
│   └── ...
├── profile_prepro
│   ├── Dockerfile
│   └── ...
├── requirements.txt
├── dcoker-compose.yml
├── README.md
├── .gitattributes
├── Notebook - ML models.ipynb
├── .gitignore
└── ...
```

## How to run DataDiscovery through Docker
### Docker Compose (Preprocessing + Modelling)

You can use Docker Compose to simplify building and running both modules: profiles_prepro and modelling.

#### Build All Services

From the project root (where `docker-compose.yml` is located), run:

```bash
docker compose build
```
#### Run profile_prepro
To execute the preprocessing pipeline (which creates data profiles and computes distances)

First make sure you have a MinIO server running and accessible. Then, upload your benchmark data to the MinIO bucket specified in the environment variables.

You can download the test benchmark data lake example [here](https://mydisk.cs.upc.edu/s/QHJbKcyeacxq35f)

Then, run the preprocessing service with the following command:
```bash
docker compose run --rm \
  -e MINIO_ENDPOINT=http://minio:9200 \
  -e MINIO_ACCESS_KEY=minioadmin \
  -e MINIO_SECRET_KEY=minioadmin123 \
  -e MINIO_BUCKET=data-based-data-discovery \
  -e MINIO_FOLDER_BENCHMARK=datalake \
  profile_prepro
```
This service is configured to fetch data from a MinIO bucket (e.g., data-based-data-discovery/datalake) if environment variables are set and MinIO is reachable via the Docker network.

#### Run modelling (with arguments)
To generate a joinability ranking using the predictive model, the following command starts an API service that listens for requests to generate rankings based on the provided dataset and attribute:

```bash
docker compose run --rm \
  -e MINIO_ENDPOINT=http://minio:9200 \
  -e MINIO_ACCESS_KEY=minioadmin \
  -e MINIO_SECRET_KEY=minioadmin123 \
  -e MINIO_BUCKET=data-based-data-discovery \
  modelling
```
Then you can make a request to the API to get a ranking. For example, using `curl`:

```bash
curl "http://localhost:8000/ranking?dataset=world_country.csv&attribute=Code&k=10"
```
Here:
- world_country.csv is the name of the query dataset (must match a profile/distances file)
- Code is the attribute to rank
- 10 is the number of top candidates to return

This command will return a JSON response with the top 10 candidates for the join based on the specified dataset and attribute.

#### MinIO Integration
The docker-compose.yml assumes that:
- A MinIO server is running externally (e.g., on the long-term-storage_default network). Change network settings in docker compose file if needed.
- The required bucket and folders already exist in MinIO

## Questions / Contact
Please reach out (aniol.bisquert@upc.edu) if you have any questions or need assistance with the DQRuleDiscovery tool.
