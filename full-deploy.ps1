# ====================================
# DistriSchool - Full Deploy Script
# PowerShell Script for Complete Deployment
# ====================================

# Function to print colored messages
function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

# ====================================
# Header
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "DistriSchool - Full Deploy Script"
Write-Info "======================================"
Write-Info ""

# ====================================
# Step 1: Check Prerequisites
# ====================================
Write-Info "Verificando pré-requisitos..."

if (-not (Test-Command "minikube")) {
    Write-Error "❌ Minikube não está instalado ou não está no PATH."
    Write-Error "Por favor, instale o Minikube: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
}

if (-not (Test-Command "kubectl")) {
    Write-Error "❌ kubectl não está instalado ou não está no PATH."
    Write-Error "Por favor, instale o kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
}

if (-not (Test-Command "docker")) {
    Write-Error "❌ Docker não está instalado ou não está no PATH."
    Write-Error "Por favor, instale o Docker: https://www.docker.com/products/docker-desktop"
    exit 1
}

Write-Success "✅ Todos os pré-requisitos estão instalados."

# ====================================
# Step 2: Start Minikube with Configuration
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Configurando Minikube"
Write-Info "======================================"
Write-Info ""
Write-Info "Verificando status do Minikube..."

$minikubeStatus = minikube status --format='{{.Host}}' 2>&1

if ($minikubeStatus -ne "Running") {
    Write-Warning "⚠️  Minikube não está rodando."
    Write-Info "Iniciando Minikube com as seguintes configurações:"
    Write-Info "  - CPUs: 4"
    Write-Info "  - Memória: 8192 MB (8 GB)"
    Write-Info "  - Driver: docker"
    Write-Info ""
    Write-Info "Isso pode levar alguns minutos..."
    
    try {
        minikube start --cpus=4 --memory=8192 --driver=docker
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao iniciar o Minikube"
        }
        Write-Success "✅ Minikube iniciado com sucesso!"
    }
    catch {
        Write-Error "❌ Erro ao iniciar o Minikube: $_"
        Write-Error "Tente iniciar manualmente com: minikube start --cpus=4 --memory=8192 --driver=docker"
        exit 1
    }
}
else {
    Write-Success "✅ Minikube já está rodando."
}

# ====================================
# Step 3: Enable Ingress Addon
# ====================================
Write-Info ""
Write-Info "Habilitando addon Ingress do Minikube..."

try {
    minikube addons enable ingress
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao habilitar ingress"
    }
    Write-Success "✅ Addon Ingress habilitado."
}
catch {
    Write-Error "❌ Erro ao habilitar Ingress: $_"
    Write-Warning "O deploy continuará, mas o Ingress pode não funcionar corretamente."
}

# ====================================
# Step 4: Configure Docker Environment
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Configurando Docker"
Write-Info "======================================"
Write-Info ""
Write-Info "Configurando ambiente Docker para usar o daemon do Minikube..."

try {
    & minikube -p minikube docker-env --shell powershell | Invoke-Expression
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao configurar o ambiente Docker"
    }
    Write-Success "✅ Ambiente Docker configurado para Minikube."
}
catch {
    Write-Error "❌ Erro ao configurar ambiente Docker: $_"
    exit 1
}

# ====================================
# Step 5: Build Docker Images
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Construindo Imagens Docker"
Write-Info "======================================"
Write-Info ""

# Save the root directory
$rootDir = Get-Location

# Function to build Docker image
function Build-DockerImage {
    param(
        [string]$ServiceName,
        [string]$FolderPath,
        [string]$ImageTag,
        [string]$Emoji
    )
    
    Write-Info ""
    Write-Info "$Emoji Building $ServiceName..."
    
    # Only change directory if FolderPath is not "." (current directory)
    if ($FolderPath -ne ".") {
        try {
            Set-Location $FolderPath
        }
        catch {
            Write-Error "❌ Erro ao navegar para $FolderPath"
            Set-Location $rootDir
            return $false
        }
    }
    
    # Check if Dockerfile exists
    if (-not (Test-Path "Dockerfile")) {
        Write-Error "❌ Dockerfile não encontrado em $(Get-Location)"
        Set-Location $rootDir
        return $false
    }
    
    # Build the image
    try {
        docker build -t $ImageTag .
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build falhou"
        }
        Write-Success "✅ $ServiceName construído com sucesso!"
        
        # Return to root directory if we changed it
        if ($FolderPath -ne ".") {
            Set-Location $rootDir
        }
        return $true
    }
    catch {
        Write-Error "❌ Erro ao construir $ServiceName : $_"
        # Return to root directory if we changed it
        if ($FolderPath -ne ".") {
            Set-Location $rootDir
        }
        return $false
    }
}

# Build all services
$buildSuccess = $true

# Professor Service (root directory)
if (-not (Build-DockerImage -ServiceName "Professor Service" -FolderPath "." -ImageTag "distrischool-professor-tecadm-service:latest" -Emoji "📚")) {
    $buildSuccess = $false
}

# Aluno Service
if (-not (Build-DockerImage -ServiceName "Aluno Service" -FolderPath ".\Distrischool-aluno-main" -ImageTag "distrischool-aluno-service:latest" -Emoji "👨‍🎓")) {
    $buildSuccess = $false
}

# User Service
if (-not (Build-DockerImage -ServiceName "User Service" -FolderPath ".\distrischool-user-service-main\user-service" -ImageTag "distrischool-user-service:latest" -Emoji "👤")) {
    $buildSuccess = $false
}

# API Gateway
if (-not (Build-DockerImage -ServiceName "API Gateway" -FolderPath ".\api-gateway" -ImageTag "distrischool-api-gateway:latest" -Emoji "🌐")) {
    $buildSuccess = $false
}

# Frontend
if (-not (Build-DockerImage -ServiceName "Frontend" -FolderPath ".\frontend" -ImageTag "distrischool-frontend:latest" -Emoji "💻")) {
    $buildSuccess = $false
}

# Make sure we're back in the root directory
Set-Location $rootDir

if (-not $buildSuccess) {
    Write-Error ""
    Write-Error "❌ Alguns builds falharam. Por favor, verifique os erros acima."
    exit 1
}

Write-Success ""
Write-Success "✅ Todas as imagens foram construídas com sucesso!"

# List built images
Write-Info ""
Write-Info "Imagens disponíveis:"
docker images | Select-String "distrischool"

# ====================================
# Step 6: Deploy Infrastructure
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Deploy - Infraestrutura"
Write-Info "======================================"
Write-Info ""

Write-Info "🐘 Aplicando PostgreSQL..."
try {
    kubectl apply -f k8s-manifests/postgres/
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao aplicar manifests do PostgreSQL"
    }
    Write-Success "✅ PostgreSQL aplicado."
}
catch {
    Write-Error "❌ Erro ao aplicar PostgreSQL: $_"
    exit 1
}

Write-Info ""
Write-Info "🐰 Aplicando RabbitMQ..."
try {
    kubectl apply -f k8s-manifests/rabbitmq/
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao aplicar manifests do RabbitMQ"
    }
    Write-Success "✅ RabbitMQ aplicado."
}
catch {
    Write-Error "❌ Erro ao aplicar RabbitMQ: $_"
    exit 1
}

Write-Info ""
Write-Info "⏳ Aguardando infraestrutura ficar pronta..."
Write-Info "   Aguardando PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s 2>&1 | Out-Null
Write-Info "   Aguardando RabbitMQ..."
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s 2>&1 | Out-Null
Write-Success "✅ Infraestrutura pronta!"

# ====================================
# Step 7: Deploy Backend Services
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Deploy - Backend Services"
Write-Info "======================================"
Write-Info ""

Write-Info "📚 Aplicando Professor Service..."
kubectl apply -f k8s-manifests/professor-service/

Write-Info ""
Write-Info "👨‍🎓 Aplicando Aluno Service..."
kubectl apply -f k8s-manifests/aluno-service/

Write-Info ""
Write-Info "👤 Aplicando User Service..."
kubectl apply -f k8s-manifests/user-service/

Write-Info ""
Write-Info "🌐 Aplicando API Gateway..."
kubectl apply -f k8s-manifests/api-gateway/

Write-Info ""
Write-Info "⏳ Aguardando backend services ficarem prontos..."
Write-Info "   Aguardando Professor Service..."
kubectl wait --for=condition=ready pod -l app=professor-tecadm-service --timeout=120s 2>&1 | Out-Null
Write-Info "   Aguardando Aluno Service..."
kubectl wait --for=condition=ready pod -l app=aluno-service --timeout=120s 2>&1 | Out-Null
Write-Info "   Aguardando User Service..."
kubectl wait --for=condition=ready pod -l app=user-service --timeout=120s 2>&1 | Out-Null
Write-Info "   Aguardando API Gateway..."
kubectl wait --for=condition=ready pod -l app=api-gateway --timeout=120s 2>&1 | Out-Null
Write-Success "✅ Backend services prontos!"

# ====================================
# Step 8: Deploy Frontend
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Deploy - Frontend"
Write-Info "======================================"
Write-Info ""

Write-Info "💻 Aplicando Frontend..."
kubectl apply -f k8s-manifests/frontend/

Write-Info ""
Write-Info "⏳ Aguardando Frontend ficar pronto..."
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s 2>&1 | Out-Null
Write-Success "✅ Frontend pronto!"

# ====================================
# Step 9: Deploy Ingress
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Deploy - Ingress"
Write-Info "======================================"
Write-Info ""

Write-Info "🌐 Aplicando Ingress..."
try {
    kubectl apply -f k8s-manifests/ingress.yaml
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao aplicar Ingress"
    }
    Write-Success "✅ Ingress aplicado."
}
catch {
    Write-Error "❌ Erro ao aplicar Ingress: $_"
    Write-Warning "O deploy continuou, mas o Ingress pode não estar funcionando."
}

# ====================================
# Step 10: Final Status and Instructions
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Success "✅ Deploy Concluído!"
Write-Info "======================================"
Write-Info ""

Write-Info "Aguardando pods iniciarem (10 segundos)..."
Start-Sleep -Seconds 10

# Display pods status
Write-Info ""
Write-Info "Status dos Pods:"
kubectl get pods -A

# Get Minikube IP
$minikubeIp = minikube ip

Write-Info ""
Write-Info "======================================"
Write-Info "Acesso ao DistriSchool"
Write-Info "======================================"
Write-Info ""

Write-Success "📌 Configuração de Hosts:"
Write-Info "Para acessar o DistriSchool via Ingress, adicione ao arquivo hosts:"
Write-Info ""
Write-Host "   Arquivo: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Yellow
Write-Host "   Linha:   $minikubeIp distrischool.local" -ForegroundColor White
Write-Info ""
Write-Info "Execute como Administrador:"
Write-Host "   Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value `"$minikubeIp distrischool.local`"" -ForegroundColor Yellow
Write-Info ""

Write-Success "🌐 URLs de Acesso:"
Write-Host "   Frontend: http://distrischool.local" -ForegroundColor Green
Write-Host "   API:      http://distrischool.local/api" -ForegroundColor Green
Write-Info ""

Write-Info "======================================"
Write-Info "Comandos Úteis"
Write-Info "======================================"
Write-Info ""

Write-Info "1. Ver status dos pods:"
Write-Host "   kubectl get pods -A" -ForegroundColor Yellow
Write-Info ""

Write-Info "2. Ver logs de um pod:"
Write-Host "   kubectl logs <nome-do-pod>" -ForegroundColor Yellow
Write-Info ""

Write-Info "3. Ver logs em tempo real:"
Write-Host "   kubectl logs -f <nome-do-pod>" -ForegroundColor Yellow
Write-Info ""

Write-Info "4. Acessar o RabbitMQ Management Console:"
Write-Host "   minikube service rabbitmq-service --url" -ForegroundColor Yellow
Write-Info "   (Use a porta 15672, usuário: guest, senha: guest)"
Write-Info ""

Write-Info "5. Testar a API:"
Write-Host "   curl http://distrischool.local/api/v1/professores" -ForegroundColor Yellow
Write-Info ""

Write-Info "6. Para limpar o ambiente:"
Write-Host "   .\clean-setup.ps1" -ForegroundColor Yellow
Write-Info ""

Write-Success "======================================"
Write-Success "Ambiente DistriSchool está pronto!"
Write-Success "======================================"
Write-Info ""
