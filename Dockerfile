# Use the official base image as a base, create a new build stage (FROM)
FROM node:22-alpine AS builder
# Set the working directory inside the container
WORKDIR /app

# Install OpenJDK 17 for the builder stage
RUN apk add --no-cache openjdk17

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Copy only the necessary Gradle files first
# Build optimization technique (layer caching)
# By copying only the Gradle-related files first, we leverage Dockers caching system.
COPY gradlew /app/gradlew
COPY gradle /app/gradle
# The Gradle Wrapper executable script (gradlew) and the Gradle Wrapper configuration files (gradle/)
COPY build.gradle /app/build.gradle
COPY settings.gradle /app/settings.gradle
# The build.gradle and settings.gradle files are the configuration files for the Gradle build system.

# This way, dependencies are only reinstalled if the configuration files change.

# Ensure gradlew has execution permissions
RUN chmod +x /app/gradlew
# Change the permissions of the Gradle Wrapper executable script to make it executable

# Copy the source code
# Original source code is copied last to leverage Docker's caching system
# If the source code changes, the cache is invalidated and the following commands are executed
# src is the source code directory, /app/src is the destination directory in the image
COPY src /app/src

# Build the application using Gradle
RUN ./gradlew clean build --no-daemon
# Execute the Gradle Wrapper script to build the application
# Finalizes the build stage by cleaning the previous build artifacts (clean)
# creating a new JAR file (build)
# running the build process without a daemon (--no-daemon) for optimization

# Second stage: Create the final image with only the JAR file
FROM openjdk:17-jdk-slim
# Set the working directory
WORKDIR /app

# Uses a minimal JDK 17 image for reduced size
# Sets up /app as the working directory

# Copy all JAR files into /app/ (without renaming the file)
COPY --from=builder /app/build/libs/*.jar /app/
# Copies the JAR file from the previous build stage to the current image
# --from=build specifies the build stage to copy from

# Expose the port the app will run on
EXPOSE 8080

# Set the environment variable for Spring profile
ENV SPRING_PROFILES_ACTIVE=prod
# Sets Spring to use production profile

# Run the application with the correct JAR file name
ENTRYPOINT ["java", "-jar", "/app/ChatApp-0.0.1-SNAPSHOT.jar"]
# Starts the Spring Boot application using the built JAR file