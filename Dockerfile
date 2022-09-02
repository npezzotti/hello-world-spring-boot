FROM openjdk:8-jdk-alpine as build
WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN ./mvnw install -DskipTests
RUN apk add --no-cache wget

EXPOSE 8080/tcp
ENTRYPOINT ["java", "-jar", "target/helloWorld-0.0.1-SNAPSHOT.jar"]
