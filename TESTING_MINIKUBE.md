# DistriSchool - Guia de Deploy no Minikube

Este documento fornece instruções passo a passo para fazer o deploy completo da plataforma DistriSchool no Minikube.

## Setup Automatizado (Recomendado)

### Para usuários Windows:
Execute o script PowerShell automatizado que realiza todo o processo:
```powershell
.\setup-dev-env.ps1
```

Este script automatiza todas as etapas descritas neste guia. Veja a seção [11. Automatização](#11-automatização-recomendado) para mais detalhes.

### Para usuários Linux/Mac:
Execute os scripts bash existentes:
```bash
./build-all.sh
./deploy-all.sh
```

---

## Setup Manual (Passo a Passo)

Se preferir executar o setup manualmente ou em caso de problemas com o script automatizado, siga as instruções abaixo.

## Pré-requisitos

- Docker instalado e funcionando
- Minikube instalado (versão 1.30+)
- kubectl instalado
- Git
- Pelo menos 8GB de RAM disponível
- Para Windows: PowerShell 5.1 ou superior

## 1. Iniciar o Minikube

```bash
# Inicie o Minikube com recursos adequados
minikube start --cpus=4 --memory=8192 --driver=docker

# Verifique o status
minikube status
```

## 2. Configurar o Ambiente Docker

Configure o terminal para usar o Docker daemon do Minikube:

```bash
# Linux/Mac
eval $(minikube docker-env)

# Windows PowerShell
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Windows CMD
@FOR /f "tokens=*" %i IN ('minikube -p minikube docker-env --shell cmd') DO @%i
```

**IMPORTANTE:** Esta configuração deve ser executada em cada novo terminal que você abrir.

## 3. Construir as Imagens Docker

### 3.1. Professor Service

```bash
cd /caminho/para/distrischool-professor-tecadm-service
docker build -t distrischool-professor-tecadm-service:latest .
```

### 3.2. Aluno Service

```bash
cd Distrischool-aluno-main
docker build -t distrischool-aluno-service:latest .
cd ..
```

### 3.3. User Service

```bash
cd distrischool-user-service-main/user-service
docker build -t distrischool-user-service:latest .
cd ../..
```

### 3.4. API Gateway

```bash
cd api-gateway
docker build -t distrischool-api-gateway:latest .
cd ..
```

### 3.5. Frontend

```bash
cd frontend
docker build -t distrischool-frontend:latest .
cd ..
```

### 3.6. Verificar as Imagens

```bash
docker images | grep distrischool
```

Você deve ver 4 imagens:
- distrischool-professor-tecadm-service:latest
- distrischool-aluno-service:latest
- distrischool-user-service:latest
- distrischool-api-gateway:latest
- distrischool-frontend:latest

## 4. Aplicar os Manifestos Kubernetes

Os manifestos devem ser aplicados na ordem correta para garantir que as dependências sejam satisfeitas.

### 4.1. Infraestrutura (PostgreSQL e RabbitMQ)

```bash
# PostgreSQL
kubectl apply -f k8s-manifests/postgres/pvc.yaml
kubectl apply -f k8s-manifests/postgres/deployment.yaml
kubectl apply -f k8s-manifests/postgres/service.yaml

# RabbitMQ
kubectl apply -f k8s-manifests/rabbitmq/deployment.yaml
kubectl apply -f k8s-manifests/rabbitmq/service.yaml
```

Aguarde os pods ficarem prontos:

```bash
kubectl get pods -w
# Pressione Ctrl+C quando todos os pods estiverem Running
```

### 4.2. Serviços de Backend

```bash
# Professor Service
kubectl apply -f k8s-manifests/professor-service/deployment.yaml
kubectl apply -f k8s-manifests/professor-service/service.yaml

# Aluno Service
kubectl apply -f k8s-manifests/aluno-service/deployment.yaml
kubectl apply -f k8s-manifests/aluno-service/service.yaml

# User Service
kubectl apply -f k8s-manifests/user-service/deployment.yaml
kubectl apply -f k8s-manifests/user-service/service.yaml
```

Aguarde os pods ficarem prontos:

```bash
kubectl get pods -w
```

### 4.3. API Gateway e Frontend

```bash
# API Gateway
kubectl apply -f k8s-manifests/api-gateway/deployment.yaml
kubectl apply -f k8s-manifests/api-gateway/service.yaml

# Frontend
kubectl apply -f k8s-manifests/frontend/deployment.yaml
kubectl apply -f k8s-manifests/frontend/service.yaml
```

## 5. Verificar o Status dos Pods

```bash
# Listar todos os pods
kubectl get pods -A

# Ver detalhes de um pod específico (se houver problemas)
kubectl describe pod <nome-do-pod>

# Ver logs de um pod
kubectl logs <nome-do-pod>

# Ver logs em tempo real
kubectl logs -f <nome-do-pod>
```

Todos os pods devem estar com status `Running` e `READY 1/1`.

## 6. Acessar os Serviços

### 6.1. Obter as URLs dos Serviços

```bash
# Frontend
minikube service frontend-service --url

# API Gateway
minikube service api-gateway-service --url

# RabbitMQ Management Console
minikube service rabbitmq-service --url
```

**Nota:** O comando `--url` mostra a URL sem abrir o navegador. Para abrir diretamente no navegador, remova o `--url`.

### 6.2. Acessar o Frontend

1. Execute `minikube service frontend-service --url`
2. Copie a URL mostrada (ex: http://192.168.49.2:30001)
3. Abra a URL no navegador
4. Você deve ver a interface do DistriSchool com a lista de professores

### 6.3. Acessar a API Gateway

```bash
# Obter a URL do API Gateway
API_URL=$(minikube service api-gateway-service --url)
echo $API_URL

# Testar o endpoint de professores
curl $API_URL/api/v1/professores

# Testar o endpoint de alunos
curl $API_URL/api/alunos

# Testar o endpoint de usuários
curl $API_URL/api/users
```

## 7. Cenários de Teste

### 7.1. Teste End-to-End: Criar um Professor

#### Via Frontend:
1. Acesse a URL do frontend no navegador
2. A lista de professores será carregada automaticamente
3. Se a lista estiver vazia, você pode criar um professor via API (ver abaixo)

#### Via API (curl):

```bash
API_URL=$(minikube service api-gateway-service --url)

# Criar um professor
curl -X POST "$API_URL/api/v1/professores" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva",
    "email": "joao.silva@example.com",
    "especialidade": "Matemática",
    "dataContratacao": "2024-01-15"
  }'

# Listar professores
curl "$API_URL/api/v1/professores"
```

#### Via API (PowerShell):

```powershell
$API_URL = minikube service api-gateway-service --url

# Criar um professor
$body = @{
    nome = "João Silva"
    email = "joao.silva@example.com"
    especialidade = "Matemática"
    dataContratacao = "2024-01-15"
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/api/v1/professores" -Method POST -Body $body -ContentType "application/json"

# Listar professores
Invoke-RestMethod -Uri "$API_URL/api/v1/professores"
```

### 7.2. Verificar Eventos no RabbitMQ

1. Acesse a URL do RabbitMQ Management Console:
   ```bash
   minikube service rabbitmq-service --url
   ```
   Nota: Use a porta 15672 (management console)

2. Login:
   - Usuário: `guest`
   - Senha: `guest`

3. Navegue para a aba "Exchanges"
4. Procure por `distrischool.events.exchange`
5. Clique na exchange e vá para "Bindings" para ver as filas conectadas

6. Criar um professor via API e depois verifique:
   - Aba "Queues" para ver se as mensagens foram processadas
   - Aba "Exchanges" -> "distrischool.events.exchange" -> "Publish message" para publicar eventos manualmente

### 7.3. Teste de Integração: Criar Aluno

```bash
API_URL=$(minikube service api-gateway-service --url)

# Criar um aluno
curl -X POST "$API_URL/api/alunos" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Maria Santos",
    "email": "maria.santos@example.com",
    "matricula": "2024001",
    "endereco": {
      "rua": "Rua A",
      "numero": "123",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01234-567"
    }
  }'

# Listar alunos
curl "$API_URL/api/alunos"
```

### 7.4. Teste de Integração: Criar Usuário

```bash
API_URL=$(minikube service api-gateway-service --url)

# Criar um usuário
curl -X POST "$API_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@example.com",
    "password": "Admin123!",
    "role": "ADMIN"
  }'

# Listar usuários
curl "$API_URL/api/users"
```

## 8. Debugging e Troubleshooting

### 8.1. Verificar Logs de um Serviço

```bash
# Listar pods
kubectl get pods

# Ver logs do professor-service
kubectl logs -f professor-tecadm-deployment-<pod-id>

# Ver logs do aluno-service
kubectl logs -f aluno-deployment-<pod-id>

# Ver logs do user-service
kubectl logs -f user-deployment-<pod-id>

# Ver logs do api-gateway
kubectl logs -f api-gateway-deployment-<pod-id>
```

### 8.2. Verificar Conexões de Rede

```bash
# Verificar serviços
kubectl get services

# Verificar endpoints
kubectl get endpoints

# Testar conectividade entre pods (exemplo: do gateway para professor-service)
kubectl exec -it <gateway-pod-name> -- wget -qO- http://professor-tecadm-service:8082/actuator/health
```

### 8.3. Problemas Comuns

#### Pod em CrashLoopBackOff

```bash
# Ver logs para identificar o erro
kubectl logs <pod-name>

# Ver eventos do pod
kubectl describe pod <pod-name>

# Causas comuns:
# - Serviço não consegue conectar ao banco de dados (verificar se postgres está running)
# - Serviço não consegue conectar ao RabbitMQ (verificar se rabbitmq está running)
# - Imagem não foi construída corretamente (reconstruir a imagem)
```

#### Pod em ImagePullBackOff

```bash
# Verificar se a imagem existe no Docker do Minikube
eval $(minikube docker-env)
docker images | grep distrischool

# Se a imagem não existir, reconstrua-a com o Docker do Minikube configurado
```

#### Erro de Conexão ao Acessar o Frontend

```bash
# Verificar se o serviço está exposto corretamente
kubectl get service frontend-service

# Verificar se o pod está rodando
kubectl get pods | grep frontend

# Tentar acessar via minikube service
minikube service frontend-service
```

### 8.4. Reiniciar um Deployment

```bash
# Deletar e reaplicar um deployment
kubectl delete deployment <deployment-name>
kubectl apply -f k8s-manifests/<service>/deployment.yaml

# Ou usar rollout restart
kubectl rollout restart deployment/<deployment-name>
```

## 9. Monitoramento

### 9.1. Dashboard do Kubernetes

```bash
# Abrir o dashboard do Kubernetes
minikube dashboard
```

### 9.2. Verificar Recursos

```bash
# CPU e memória dos pods
kubectl top pods

# CPU e memória dos nodes
kubectl top nodes
```

## 10. Limpeza

### 10.1. Deletar Todos os Resources

```bash
# Deletar frontend
kubectl delete -f k8s-manifests/frontend/

# Deletar API Gateway
kubectl delete -f k8s-manifests/api-gateway/

# Deletar serviços de backend
kubectl delete -f k8s-manifests/user-service/
kubectl delete -f k8s-manifests/aluno-service/
kubectl delete -f k8s-manifests/professor-service/

# Deletar infraestrutura
kubectl delete -f k8s-manifests/rabbitmq/
kubectl delete -f k8s-manifests/postgres/
```

### 10.2. Parar o Minikube

```bash
# Parar o Minikube
minikube stop

# Deletar o cluster (cuidado: remove tudo)
minikube delete
```

## 11. Automatização (Recomendado)

### 11.1. Script Automatizado Completo (Windows PowerShell)

Para usuários Windows, existe um script PowerShell que automatiza todo o processo de setup:

**`setup-dev-env.ps1`** - Script completo que:
- Verifica pré-requisitos (Docker, Minikube, kubectl)
- Inicia o Minikube se não estiver rodando
- Configura o ambiente Docker para usar o daemon do Minikube
- Constrói todas as imagens Docker
- Aplica todos os manifestos Kubernetes na ordem correta
- Exibe instruções finais de acesso

**Execução:**
```powershell
# Execute o script no diretório raiz do projeto
.\setup-dev-env.ps1
```

**Nota:** O script pode solicitar permissões de execução. Para habilitar a execução de scripts PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 11.2. Scripts para Linux/Mac

#### 11.2.1. Script para Build de Todas as Imagens

O arquivo `build-all.sh` constrói todas as imagens Docker:

```bash
#!/bin/bash
set -e

echo "Configurando Docker para usar Minikube..."
eval $(minikube docker-env)

echo "Building Professor Service..."
docker build -t distrischool-professor-tecadm-service:latest .

echo "Building Aluno Service..."
cd Distrischool-aluno-main
docker build -t distrischool-aluno-service:latest .
cd ..

echo "Building User Service..."
cd distrischool-user-service-main/user-service
docker build -t distrischool-user-service:latest .
cd ../..

echo "Building API Gateway..."
cd api-gateway
docker build -t distrischool-api-gateway:latest .
cd ..

echo "Building Frontend..."
cd frontend
docker build -t distrischool-frontend:latest .
cd ..

echo "All images built successfully!"
docker images | grep distrischool
```

Execute:
```bash
chmod +x build-all.sh
./build-all.sh
```

#### 11.2.2. Script para Deploy Completo

O arquivo `deploy-all.sh` faz o deploy de todos os serviços:

```bash
#!/bin/bash
set -e

echo "Deploying infrastructure..."
kubectl apply -f k8s-manifests/postgres/
kubectl apply -f k8s-manifests/rabbitmq/

echo "Waiting for infrastructure to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s

echo "Deploying backend services..."
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/

echo "Waiting for backend services to be ready..."
kubectl wait --for=condition=ready pod -l app=professor-tecadm --timeout=300s
kubectl wait --for=condition=ready pod -l app=aluno --timeout=300s
kubectl wait --for=condition=ready pod -l app=user --timeout=300s

echo "Deploying API Gateway and Frontend..."
kubectl apply -f k8s-manifests/api-gateway/
kubectl apply -f k8s-manifests/frontend/

echo "Waiting for API Gateway and Frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s

echo "Deployment complete!"
echo ""
echo "Access URLs:"
echo "Frontend: $(minikube service frontend-service --url)"
echo "API Gateway: $(minikube service api-gateway-service --url)"
echo "RabbitMQ Console: $(minikube service rabbitmq-service --url | grep 15672)"
```

Execute:
```bash
chmod +x deploy-all.sh
./deploy-all.sh
```

## 12. Referências

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Spring Cloud Gateway Documentation](https://spring.io/projects/spring-cloud-gateway)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)

## 13. Suporte

Para problemas ou dúvidas:
1. Verifique os logs dos pods com `kubectl logs`
2. Verifique o status dos recursos com `kubectl get all`
3. Consulte o dashboard do Kubernetes com `minikube dashboard`
4. Consulte a documentação do contrato de mensageria em `MESSAGING_CONTRACT.md`
