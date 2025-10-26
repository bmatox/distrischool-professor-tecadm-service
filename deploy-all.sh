#!/bin/bash
# Script to deploy all services to Kubernetes
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
echo "⏳ Waiting for infrastructure to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s || echo "Timeout waiting for PostgreSQL"
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s || echo "Timeout waiting for RabbitMQ"

echo ""
echo "🎓 Deploying Backend Services..."
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/

echo ""
echo "⏳ Waiting for backend services to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l app=professor-tecadm --timeout=300s || echo "Timeout waiting for Professor Service"
kubectl wait --for=condition=ready pod -l app=aluno --timeout=300s || echo "Timeout waiting for Aluno Service"
kubectl wait --for=condition=ready pod -l app=user --timeout=300s || echo "Timeout waiting for User Service"

echo ""
echo "🌐 Deploying API Gateway and Frontend..."
kubectl apply -f k8s-manifests/api-gateway/
kubectl apply -f k8s-manifests/frontend/

echo ""
echo "⏳ Waiting for API Gateway and Frontend to be ready..."
sleep 10
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=300s || echo "Timeout waiting for API Gateway"
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s || echo "Timeout waiting for Frontend"

echo ""
echo "✅ Deploy completed successfully!"
echo ""
echo "======================================"
echo "Access URLs:"
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
echo "To open the Frontend in your browser, run:"
echo "  minikube service frontend-service"
echo ""
echo "To view all pods:"
echo "  kubectl get pods"
echo ""
echo "To view logs for a pod:"
echo "  kubectl logs <pod-name>"
