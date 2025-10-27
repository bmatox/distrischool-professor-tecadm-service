#!/bin/bash

# Script para testar a configuração CORS do API Gateway
# Uso: ./test-cors.sh [URL_DO_API_GATEWAY]

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# URL do API Gateway (pode ser passada como argumento)
# Default usa porta dinâmica do Minikube - obtenha com: minikube service api-gateway-service --url
API_GATEWAY_URL="${1:-http://127.0.0.1:54717}"
FRONTEND_ORIGIN="http://127.0.0.1:60002"

echo "============================================"
echo "Teste de Configuração CORS"
echo "============================================"
echo ""
echo "API Gateway URL: $API_GATEWAY_URL"
echo "Frontend Origin: $FRONTEND_ORIGIN"
echo ""

# Função para testar preflight request (OPTIONS)
test_preflight() {
    local endpoint=$1
    local url="${API_GATEWAY_URL}${endpoint}"
    
    echo -e "${YELLOW}Testando preflight request para: ${endpoint}${NC}"
    
    response=$(curl -s -i -X OPTIONS "$url" \
        -H "Origin: $FRONTEND_ORIGIN" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Content-Type" \
        2>&1)
    
    if echo "$response" | grep -q "Access-Control-Allow-Origin:"; then
        echo -e "${GREEN}✓ Header Access-Control-Allow-Origin encontrado${NC}"
        echo "$response" | grep "Access-Control-Allow-Origin:"
    else
        echo -e "${RED}✗ Header Access-Control-Allow-Origin NÃO encontrado${NC}"
        return 1
    fi
    
    if echo "$response" | grep -q "Access-Control-Allow-Methods:"; then
        echo -e "${GREEN}✓ Header Access-Control-Allow-Methods encontrado${NC}"
        echo "$response" | grep "Access-Control-Allow-Methods:"
    else
        echo -e "${YELLOW}⚠ Header Access-Control-Allow-Methods NÃO encontrado${NC}"
    fi
    
    if echo "$response" | grep -q "Access-Control-Max-Age:"; then
        echo -e "${GREEN}✓ Header Access-Control-Max-Age encontrado${NC}"
        echo "$response" | grep "Access-Control-Max-Age:"
    else
        echo -e "${YELLOW}⚠ Header Access-Control-Max-Age NÃO encontrado${NC}"
    fi
    
    echo ""
    return 0
}

# Função para testar requisição GET com CORS
test_get_request() {
    local endpoint=$1
    local url="${API_GATEWAY_URL}${endpoint}"
    
    echo -e "${YELLOW}Testando requisição GET para: ${endpoint}${NC}"
    
    response=$(curl -s -i -X GET "$url" \
        -H "Origin: $FRONTEND_ORIGIN" \
        2>&1)
    
    if echo "$response" | grep -q "Access-Control-Allow-Origin:"; then
        echo -e "${GREEN}✓ Header Access-Control-Allow-Origin encontrado${NC}"
        echo "$response" | grep "Access-Control-Allow-Origin:"
    else
        echo -e "${RED}✗ Header Access-Control-Allow-Origin NÃO encontrado${NC}"
        return 1
    fi
    
    # Verificar status code
    status_code=$(echo "$response" | grep "HTTP/" | head -1 | awk '{print $2}')
    echo "Status Code: $status_code"
    
    if [ "$status_code" == "200" ] || [ "$status_code" == "404" ]; then
        echo -e "${GREEN}✓ Status code válido ($status_code)${NC}"
    elif [ "$status_code" == "403" ]; then
        echo -e "${RED}✗ Status 403 Forbidden - Possível problema de segurança no backend${NC}"
    else
        echo -e "${YELLOW}⚠ Status code: $status_code${NC}"
    fi
    
    echo ""
    return 0
}

echo "============================================"
echo "Teste 1: Preflight Request (OPTIONS)"
echo "============================================"
echo ""
test_preflight "/api/v1/professores" || echo -e "${RED}Falha no teste de preflight${NC}"

echo "============================================"
echo "Teste 2: GET Request com CORS Headers"
echo "============================================"
echo ""
test_get_request "/api/v1/professores" || echo -e "${RED}Falha no teste GET${NC}"

echo "============================================"
echo "Resumo"
echo "============================================"
echo ""
echo "Se todos os testes passaram:"
echo -e "  ${GREEN}✓ CORS está configurado corretamente!${NC}"
echo ""
echo "Se os testes falharam:"
echo "  1. Verifique se o API Gateway está rodando"
echo "  2. Confirme a URL correta do API Gateway"
echo "  3. Verifique os logs: kubectl logs -f deployment/api-gateway-deployment"
echo ""
echo "Para testar no navegador:"
echo "  1. Abra o Frontend em: http://127.0.0.1:60002"
echo "  2. Abra DevTools (F12) → Console"
echo "  3. Execute:"
echo "     fetch('${API_GATEWAY_URL}/api/v1/professores')"
echo "       .then(r => console.log('Success:', r.status))"
echo "       .catch(e => console.error('Error:', e))"
echo ""
