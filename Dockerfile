FROM eclipse-temurin:21-jdk

WORKDIR /app
COPY target/springboot-devsecops-lab-1.0.0.jar app.jar

EXPOSE 8080
ENV LAB_ADMIN_PASSWORD=Admin123!

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
