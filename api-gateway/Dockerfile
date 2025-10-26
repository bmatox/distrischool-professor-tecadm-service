# =============================================================
# ETAPA 1: Build da Aplicação com Maven
# =============================================================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copia o pom.xml e baixa as dependências
COPY pom.xml .
RUN mvn dependency:go-offline

# Copia o código-fonte
COPY src ./src

# Compila a aplicação
RUN mvn clean package -DskipTests

# =============================================================
# ETAPA 2: Imagem Final de Execução
# =============================================================
FROM openjdk:17-slim

LABEL authors="DistriSchool Team"

WORKDIR /app

# Copia o artefato compilado
COPY --from=build /app/target/*.jar app.jar

# Expõe a porta 8888
EXPOSE 8888

# Comando para executar a aplicação
ENTRYPOINT ["java", "-jar", "app.jar"]
