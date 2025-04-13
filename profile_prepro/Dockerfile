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

# Give execute permissions to the script
RUN chmod +x profile_pipeline.sh

# Define mountable volumes (optional)
VOLUME ["/benchmark", "/ground_truths", "/output", "/profiles"]

# Set default command to run the pipeline
CMD ["./profile_pipeline.sh"]
