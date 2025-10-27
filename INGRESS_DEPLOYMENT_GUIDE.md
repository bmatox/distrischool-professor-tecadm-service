# DistriSchool - Guia de Deploy com Ingress

Este guia detalha como fazer o deploy completo do DistriSchool no Minikube usando Ingress para URLs estáveis.

## 🎯 Objetivo

Configurar o DistriSchool com URLs estáveis usando Ingress, eliminando a necessidade de portas dinâmicas NodePort.

**Antes (NodePort):** 
- Frontend: http://127.0.0.1:60002 (porta muda a cada reinício)
- API: http://127.0.0.1:54717 (porta muda a cada reinício)

**Depois (Ingress):**
- Frontend: http://distrischool.local
- API: http://distrischool.local/api

## 📋 Pré-requisitos

- Minikube instalado (versão 1.30+)
- kubectl instalado
- Docker instalado
- Pelo menos 8GB de RAM disponível

## 🚀 Passos de Deploy

### 1. Iniciar o Minikube

```bash
# Iniciar com recursos adequados
minikube start --cpus=4 --memory=8192

# Verificar status
minikube status
```

### 2. Habilitar o Ingress Controller

```bash
# Habilitar addon nginx-ingress
minikube addons enable ingress

# Verificar se está rodando (pode levar 1-2 minutos)
kubectl get pods -n ingress-nginx -w

# Espere até que todos os pods estejam Running e Ready
```

### 3. Configurar Docker para usar Minikube

```bash
# Linux/Mac
eval $(minikube docker-env)

# Windows PowerShell
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Verificar
docker ps
```

### 4. Construir Todas as Imagens Docker

```bash
cd /caminho/para/distrischool-professor-tecadm-service

# Professor Service
docker build -t distrischool-professor-tecadm-service:latest .

# Aluno Service
cd distrischool-aluno-main
docker build -t distrischool-aluno-service:latest .
cd ..

# User Service
cd distrischool-user-service-main/user-service
docker build -t distrischool-user-service:latest .
cd ../..

# API Gateway
cd api-gateway
docker build -t distrischool-api-gateway:latest .
cd ..

# Frontend (com as novas mudanças)
cd frontend
docker build -t distrischool-frontend:latest .
cd ..

# Verificar imagens
docker images | grep distrischool
```

### 5. Deploy da Infraestrutura

```bash
# PostgreSQL
kubectl apply -f k8s-manifests/postgres/

# RabbitMQ
kubectl apply -f k8s-manifests/rabbitmq/

# Aguardar infraestrutura estar pronta
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s
```

### 6. Deploy dos Serviços de Backend

```bash
# Professor Service
kubectl apply -f k8s-manifests/professor-service/

# Aluno Service
kubectl apply -f k8s-manifests/aluno-service/

# User Service
kubectl apply -f k8s-manifests/user-service/

# API Gateway
kubectl apply -f k8s-manifests/api-gateway/

# Aguardar serviços estarem prontos
kubectl wait --for=condition=ready pod -l app=professor-tecadm-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=aluno-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=user-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=120s
```

### 7. Deploy do Frontend

```bash
# Frontend
kubectl apply -f k8s-manifests/frontend/

# Aguardar frontend estar pronto
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s
```

### 8. Deploy do Ingress

```bash
# Aplicar configuração do Ingress
kubectl apply -f k8s-manifests/ingress.yaml

# Verificar Ingress
kubectl get ingress

# Ver detalhes
kubectl describe ingress distrischool-ingress
```

### 9. Configurar /etc/hosts

Obtenha o IP do Minikube:

```bash
minikube ip
# Exemplo: 192.168.49.2
```

Adicione ao arquivo `/etc/hosts`:

**Linux/Mac:**
```bash
echo "$(minikube ip) distrischool.local" | sudo tee -a /etc/hosts
```

**Windows (executar PowerShell como Administrador):**
```powershell
$minikubeIp = minikube ip
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$minikubeIp distrischool.local"
```

### 10. Verificar o Deploy

```bash
# Ver todos os pods
kubectl get pods

# Ver serviços
kubectl get services

# Ver ingress
kubectl get ingress

# Ver detalhes de um pod específico (se houver problema)
kubectl describe pod <pod-name>

# Ver logs de um pod
kubectl logs <pod-name>
```

Todos os pods devem estar no estado `Running` e `Ready 1/1`.

### 11. Testar o Acesso

**Browser:**
1. Abra: http://distrischool.local
2. Você deve ver o Dashboard do DistriSchool

**cURL (API Gateway):**
```bash
curl http://distrischool.local/api/v1/professores
```

## 🔄 Scripts Automatizados

### Script Completo de Build e Deploy (Bash)

Crie um arquivo `deploy-with-ingress.sh`:

```bash
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
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s

# 4. Deploy serviços
echo "⚙️ Fazendo deploy dos serviços..."
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/
kubectl apply -f k8s-manifests/api-gateway/
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
```

Execute:
```bash
chmod +x deploy-with-ingress.sh
./deploy-with-ingress.sh
```

### Script PowerShell para Windows

Crie um arquivo `deploy-with-ingress.ps1`:

```powershell
Write-Host "🚀 Deploy DistriSchool com Ingress" -ForegroundColor Green

# 1. Configurar Docker
Write-Host "📦 Configurando Docker para Minikube..." -ForegroundColor Yellow
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# 2. Build das imagens
Write-Host "🏗️ Construindo imagens Docker..." -ForegroundColor Yellow
docker build -t distrischool-professor-tecadm-service:latest .
Push-Location distrischool-aluno-main
docker build -t distrischool-aluno-service:latest .
Pop-Location
Push-Location distrischool-user-service-main\user-service
docker build -t distrischool-user-service:latest .
Pop-Location
Push-Location api-gateway
docker build -t distrischool-api-gateway:latest .
Pop-Location
Push-Location frontend
docker build -t distrischool-frontend:latest .
Pop-Location

# 3. Deploy infraestrutura
Write-Host "🗄️ Fazendo deploy da infraestrutura..." -ForegroundColor Yellow
kubectl apply -f k8s-manifests/postgres/
kubectl apply -f k8s-manifests/rabbitmq/
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s

# 4. Deploy serviços
Write-Host "⚙️ Fazendo deploy dos serviços..." -ForegroundColor Yellow
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/
kubectl apply -f k8s-manifests/api-gateway/
kubectl wait --for=condition=ready pod -l app=professor-tecadm-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=aluno-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=user-service --timeout=120s
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=120s

# 5. Deploy frontend
Write-Host "🎨 Fazendo deploy do frontend..." -ForegroundColor Yellow
kubectl apply -f k8s-manifests/frontend/
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s

# 6. Deploy Ingress
Write-Host "🌐 Configurando Ingress..." -ForegroundColor Yellow
kubectl apply -f k8s-manifests/ingress.yaml

# 7. Informações
Write-Host ""
Write-Host "✅ Deploy concluído!" -ForegroundColor Green
Write-Host ""
$minikubeIp = minikube ip
Write-Host "📌 Adicione ao arquivo hosts:" -ForegroundColor Cyan
Write-Host "C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
Write-Host "$minikubeIp distrischool.local" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Acesse:" -ForegroundColor Cyan
Write-Host "  Frontend: http://distrischool.local" -ForegroundColor White
Write-Host "  API:      http://distrischool.local/api" -ForegroundColor White
```

Execute (como Administrador):
```powershell
.\deploy-with-ingress.ps1
```

## 🔧 Configuração Dinâmica do Frontend

O frontend agora suporta configuração dinâmica da URL da API através do arquivo `/config.js`:

### Opção 1: Usando Ingress (Recomendado)

O arquivo `public/config.js` já está configurado para usar o caminho relativo `/api`:

```javascript
window.DISTRISCHOOL_CONFIG = {
  apiUrl: '/api',
  environment: 'production'
};
```

Nenhuma mudança necessária! O frontend automaticamente usará o Ingress.

### Opção 2: Usando NodePort (Fallback)

Se preferir usar NodePort, atualize o `config.js` dentro do pod:

```bash
# Obter a URL do API Gateway
GATEWAY_URL=$(minikube service api-gateway-service --url)

# Editar o config.js no pod do frontend
kubectl exec deployment/frontend-deployment -- sh -c "cat > /usr/share/nginx/html/config.js << EOF
window.DISTRISCHOOL_CONFIG = {
  apiUrl: '$GATEWAY_URL',
  environment: 'production'
};
EOF"

# Recarregar a página no navegador
```

## 🔍 Troubleshooting

### Ingress não funciona

```bash
# Verificar se o addon está habilitado
minikube addons list | grep ingress

# Habilitar se necessário
minikube addons enable ingress

# Verificar pods do Ingress Controller
kubectl get pods -n ingress-nginx

# Ver logs do Ingress Controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Pods não inicializam

```bash
# Ver status dos pods
kubectl get pods

# Ver detalhes de um pod problemático
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Frontend não carrega

```bash
# Verificar se o frontend está rodando
kubectl get pods | grep frontend

# Ver logs do frontend
kubectl logs -f deployment/frontend-deployment

# Testar acesso direto ao pod
kubectl port-forward deployment/frontend-deployment 8080:80
# Acesse: http://localhost:8080
```

### API não responde

```bash
# Verificar API Gateway
kubectl logs -f deployment/api-gateway-deployment

# Testar acesso direto
kubectl port-forward deployment/api-gateway-deployment 8080:8080
# Teste: curl http://localhost:8080/api/v1/professores
```

### Erro CORS persiste

```bash
# Verificar configuração do Gateway
kubectl exec deployment/api-gateway-deployment -- cat /app/resources/application.yml | grep -A 10 cors

# Rebuild e redeploy do Gateway
cd api-gateway
docker build -t distrischool-api-gateway:latest .
kubectl rollout restart deployment/api-gateway-deployment
kubectl rollout status deployment/api-gateway-deployment
```

## 🧹 Limpeza

Para remover tudo:

```bash
# Deletar todos os recursos
kubectl delete -f k8s-manifests/ingress.yaml
kubectl delete -f k8s-manifests/frontend/
kubectl delete -f k8s-manifests/api-gateway/
kubectl delete -f k8s-manifests/user-service/
kubectl delete -f k8s-manifests/aluno-service/
kubectl delete -f k8s-manifests/professor-service/
kubectl delete -f k8s-manifests/rabbitmq/
kubectl delete -f k8s-manifests/postgres/

# Remover entrada do /etc/hosts
# Linux/Mac:
sudo sed -i '/distrischool.local/d' /etc/hosts

# Parar Minikube
minikube stop

# Deletar Minikube (cuidado!)
minikube delete
```

## ✅ Checklist de Validação

- [ ] Minikube iniciado
- [ ] Ingress addon habilitado
- [ ] Todas as imagens construídas
- [ ] Todos os pods rodando (kubectl get pods)
- [ ] Ingress criado (kubectl get ingress)
- [ ] Entrada adicionada ao /etc/hosts
- [ ] Frontend acessível em http://distrischool.local
- [ ] API acessível em http://distrischool.local/api
- [ ] Nenhum erro CORS no console do navegador
- [ ] Dados podem ser criados e listados

## 📚 Recursos Adicionais

- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Guia completo de testes
- [README.md](./README.md) - Documentação geral do projeto
- [CORS_FIX_SUMMARY.md](./CORS_FIX_SUMMARY.md) - Detalhes da correção CORS

---

**Versão:** 1.0  
**Data:** 2025-10-27  
**Autor:** DistriSchool Team
