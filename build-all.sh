#!/bin/bash
# Script para construir todas as imagens Docker no Minikube
set -e

echo "======================================"
echo "DistriSchool - Build All Docker Images"
echo "======================================"
echo ""

# Configurar Docker para usar o daemon do Minikube
echo "Configurando Docker para usar Minikube daemon..."
eval $(minikube docker-env)

# Build Professor Service
echo ""
echo "📚 Building Professor Service..."
docker build -t distrischool-professor-tecadm-service:latest .

# Build Aluno Service
echo ""
echo "👨‍🎓 Building Aluno Service..."
cd Distrischool-aluno-main
docker build -t distrischool-aluno-service:latest .
cd ..

# Build User Service
echo ""
echo "👤 Building User Service..."
cd distrischool-user-service-main/user-service
docker build -t distrischool-user-service:latest .
cd ../..

# Build API Gateway
echo ""
echo "🌐 Building API Gateway..."
cd api-gateway
docker build -t distrischool-api-gateway:latest .
cd ..

# Build Frontend
echo ""
echo "💻 Building Frontend..."
cd frontend
docker build -t distrischool-frontend:latest .
cd ..

echo ""
echo "✅ Todas as imagens foram construídas com sucesso!"
echo ""
echo "Imagens disponíveis:"
docker images | grep distrischool

echo ""
echo "Próximo passo: Execute ./deploy-all.sh para fazer o deploy no Kubernetes"
