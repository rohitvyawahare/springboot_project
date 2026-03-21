# Backend Dockerfile (Spring Boot)
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /workspace

# Copy only Maven config first to leverage layer caching
COPY helloworld/pom.xml ./
COPY helloworld/src ./src

RUN mvn -B package -DskipTests

# Runtime image
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Expose Spring Boot default port
EXPOSE 8080

# Copy executable jar from build stage
COPY --from=build /workspace/target/helloworld-0.0.1-SNAPSHOT.jar /app/app.jar

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
