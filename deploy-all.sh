#!/bin/bash
# Script para fazer deploy de todos os serviços no Kubernetes
set -e

echo "======================================"
echo "DistriSchool - Deploy All Services"
echo "======================================"
echo ""

# Deploy Infrastructure
echo "🗄️  Deploying Infrastructure (PostgreSQL and RabbitMQ)..."
kubectl apply -f k8s-manifests/postgres/
kubectl apply -f k8s-manifests/rabbitmq/

echo ""
echo "⏳ Aguardando infraestrutura ficar pronta..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s || echo "Timeout aguardando PostgreSQL"
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s || echo "Timeout aguardando RabbitMQ"

echo ""
echo "🎓 Deploying Backend Services..."
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/

echo ""
echo "⏳ Aguardando serviços de backend ficarem prontos..."
sleep 10
kubectl wait --for=condition=ready pod -l app=professor-tecadm --timeout=300s || echo "Timeout aguardando Professor Service"
kubectl wait --for=condition=ready pod -l app=aluno --timeout=300s || echo "Timeout aguardando Aluno Service"
kubectl wait --for=condition=ready pod -l app=user --timeout=300s || echo "Timeout aguardando User Service"

echo ""
echo "🌐 Deploying API Gateway and Frontend..."
kubectl apply -f k8s-manifests/api-gateway/
kubectl apply -f k8s-manifests/frontend/

echo ""
echo "⏳ Aguardando API Gateway e Frontend ficarem prontos..."
sleep 10
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=300s || echo "Timeout aguardando API Gateway"
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s || echo "Timeout aguardando Frontend"

echo ""
echo "✅ Deploy completo!"
echo ""
echo "======================================"
echo "URLs de Acesso:"
echo "======================================"
echo ""
echo "Frontend:"
minikube service frontend-service --url
echo ""
echo "API Gateway:"
minikube service api-gateway-service --url
echo ""
echo "RabbitMQ Management Console:"
minikube service rabbitmq-service --url | grep 15672
echo ""
echo "Para abrir o Frontend no navegador, execute:"
echo "  minikube service frontend-service"
echo ""
echo "Para ver todos os pods:"
echo "  kubectl get pods"
echo ""
echo "Para ver os logs de um pod:"
echo "  kubectl logs <pod-name>"
