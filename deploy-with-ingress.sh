#!/bin/bash
set -e

echo "🚀 Deploy DistriSchool com Ingress"

# 1. Configurar Docker
echo "📦 Configurando Docker para Minikube..."
eval $(minikube docker-env)

# 2. Build das imagens
echo "🏗️ Construindo imagens Docker..."
docker build -t distrischool-professor-tecadm-service:latest .
cd distrischool-aluno-main && docker build -t distrischool-aluno-service:latest . && cd ..
cd distrischool-user-service-main/user-service && docker build -t distrischool-user-service:latest . && cd ../..
cd api-gateway && docker build -t distrischool-api-gateway:latest . && cd ..
cd frontend && docker build -t distrischool-frontend:latest . && cd ..

# 3. Deploy infraestrutura
echo "🗄️ Fazendo deploy da infraestrutura..."
kubectl apply -f k8s-manifests/postgres/
kubectl apply -f k8s-manifests/rabbitmq/
echo "⏳ Aguardando infraestrutura..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s

# 4. Deploy serviços
echo "⚙️ Fazendo deploy dos serviços..."
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/
kubectl apply -f k8s-manifests/api-gateway/
echo "⏳ Aguardando serviços..."
kubectl wait --for=condition=ready pod -l app=professor-tecadm-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=aluno-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=user-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=120s

# 5. Deploy frontend
echo "🎨 Fazendo deploy do frontend..."
kubectl apply -f k8s-manifests/frontend/
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s

# 6. Deploy Ingress
echo "🌐 Configurando Ingress..."
kubectl apply -f k8s-manifests/ingress.yaml

# 7. Informações
echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📌 Adicione ao /etc/hosts:"
echo "$(minikube ip) distrischool.local"
echo ""
echo "🌐 Acesse:"
echo "  Frontend: http://distrischool.local"
echo "  API:      http://distrischool.local/api"
echo ""
echo "📝 Para testar, execute: curl http://distrischool.local/api/v1/professores"
