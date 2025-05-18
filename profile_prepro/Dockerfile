# Use Gradle with JDK 21 to build the JAR
FROM gradle:8.5-jdk21 AS builder

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

RUN gradle build

# Build the fat JAR using Shadow plugin
RUN gradle shadowJar

# Debug: List the contents of the build/libs directory
RUN ls -la /app/build/libs

# Use a lightweight JDK 21 image for running the JAR
FROM eclipse-temurin:21-jdk

# Set working directory inside the container
WORKDIR /app

# Copy the built JAR and shell script from the builder stage
COPY --from=builder /app/build/libs/app-all.jar ./DataDiscovery-all.jar
COPY profile_pipeline.sh .
COPY profile_pipeline_minio.sh .

# Give execute permissions to the script
RUN chmod +x profile_pipeline.sh
RUN chmod +x profile_pipeline_minio.sh


RUN apt-get update && apt-get install -y wget && \
    wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/bin/mc && \
    chmod +x /usr/bin/mc

# Set default command to run the pipeline
CMD ["./profile_pipeline_minio.sh"]
