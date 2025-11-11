FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN ./mvnw dependency:go-offline
COPY src src
RUN ./mvnw package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS otel-agent
ARG OTEL_JAVAAGENT_VERSION=2.8.0
RUN apk add --no-cache curl \
	&& mkdir -p /otel \
	&& curl -fsSL -o /otel/opentelemetry-javaagent.jar \
		"https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVAAGENT_VERSION}/opentelemetry-javaagent.jar"

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=otel-agent /otel/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
COPY --from=build /app/target/*.war app.war
EXPOSE 8080
ENTRYPOINT ["java", "-javaagent:/otel/opentelemetry-javaagent.jar", "-jar", "app.war"]
