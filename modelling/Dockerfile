# Step 1: Use an official Python runtime as the base image
FROM python:3.9-slim

# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy the requirements.txt file to the container
COPY requirements.txt /app/

# Step 4: Install necessary Python dependencies using requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Step 5: Copy your Python script and model into the container
COPY get_ranking.py /app/get_ranking.py
COPY predictive_model.pkl /app/predictive_model.pkl

# Step 6: Set the entrypoint to run the Python script
ENTRYPOINT ["python", "get_ranking.py"]

# Step 7: (Optional) Allow passing command-line arguments to the script (e.g., via CMD)
CMD ["--help"]
