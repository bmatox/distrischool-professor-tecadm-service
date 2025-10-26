#!/bin/bash
# Script para limpar todos os recursos do Kubernetes
set -e

echo "======================================"
echo "DistriSchool - Cleanup All Resources"
echo "======================================"
echo ""

echo "🗑️  Removendo Frontend..."
kubectl delete -f k8s-manifests/frontend/ --ignore-not-found=true

echo ""
echo "🗑️  Removendo API Gateway..."
kubectl delete -f k8s-manifests/api-gateway/ --ignore-not-found=true

echo ""
echo "🗑️  Removendo Backend Services..."
kubectl delete -f k8s-manifests/user-service/ --ignore-not-found=true
kubectl delete -f k8s-manifests/aluno-service/ --ignore-not-found=true
kubectl delete -f k8s-manifests/professor-service/ --ignore-not-found=true

echo ""
echo "🗑️  Removendo Infrastructure..."
kubectl delete -f k8s-manifests/rabbitmq/ --ignore-not-found=true
kubectl delete -f k8s-manifests/postgres/ --ignore-not-found=true

echo ""
echo "✅ Todos os recursos foram removidos!"
echo ""
echo "Para verificar se tudo foi removido:"
echo "  kubectl get all"
echo ""
echo "Para parar o Minikube:"
echo "  minikube stop"
echo ""
echo "Para deletar completamente o cluster Minikube:"
echo "  minikube delete"
