# Image Alpine avec Java (comme le workshop)
FROM alpine:latest

# Installer Java 17 et Maven (tout en un)
RUN apk add --no-cache openjdk17 maven

# Définir le répertoire de travail
WORKDIR /app

# Copier tout le projet
COPY . .

# Construire l'application
RUN mvn clean package -DskipTests

# Exposer le port
EXPOSE 8080

# Lancer l'application
CMD ["java", "-jar", "target/*.jar"]
