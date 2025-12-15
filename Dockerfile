FROM alpine:latest

RUN apk add --no-cache openjdk17 maven

WORKDIR /app
COPY . .

RUN mvn clean package -DskipTests

EXPOSE 8080

CMD ["java", "-jar", "target/student-management-0.0.1-SNAPSHOT.jar"]
