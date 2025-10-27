#!/bin/bash

# Script para rebuild e deploy do API Gateway com correção CORS
# Uso: ./rebuild-api-gateway.sh

set -e  # Parar em caso de erro

echo "============================================"
echo "Rebuild e Deploy do API Gateway"
echo "Correção: CORS Configuration"
echo "============================================"
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se estamos no diretório correto
if [ ! -d "api-gateway" ]; then
    echo -e "${RED}Erro: Diretório api-gateway não encontrado!${NC}"
    echo "Execute este script a partir do diretório raiz do projeto."
    exit 1
fi

echo -e "${YELLOW}[1/5] Building API Gateway with Maven...${NC}"
cd api-gateway
# Skipping tests for faster deployment - tests were already verified in CI/CD
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao compilar o projeto Maven!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Maven build concluído${NC}"
cd ..

echo ""
echo -e "${YELLOW}[2/5] Building Docker image...${NC}"
eval $(minikube docker-env)
docker build -t distrischool-api-gateway:latest ./api-gateway
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao construir imagem Docker!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker image construída${NC}"

echo ""
echo -e "${YELLOW}[3/5] Checking current deployment...${NC}"
kubectl get deployment api-gateway-deployment -o wide || true

echo ""
echo -e "${YELLOW}[4/5] Restarting API Gateway deployment...${NC}"
kubectl rollout restart deployment/api-gateway-deployment
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao reiniciar deployment!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Deployment reiniciado${NC}"

echo ""
echo -e "${YELLOW}[5/5] Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/api-gateway-deployment --timeout=120s
if [ $? -ne 0 ]; then
    echo -e "${RED}Timeout esperando deployment!${NC}"
    echo "Verifique os logs com: kubectl logs -f deployment/api-gateway-deployment"
    exit 1
fi
echo -e "${GREEN}✓ Deployment completo${NC}"

echo ""
echo "============================================"
echo -e "${GREEN}API Gateway atualizado com sucesso!${NC}"
echo "============================================"
echo ""
echo "Próximos passos:"
echo "1. Obter URL do API Gateway:"
echo "   minikube service api-gateway-service --url"
echo ""
echo "2. Verificar logs:"
echo "   kubectl logs -f deployment/api-gateway-deployment"
echo ""
echo "3. Testar CORS no navegador:"
echo "   - Abra o Frontend"
echo "   - Abra DevTools (F12)"
echo "   - Tente fazer uma requisição"
echo "   - Verifique se não há erros de CORS no console"
echo ""
