# ====================================
# DistriSchool - Setup Development Environment
# PowerShell Script for Windows/Minikube
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
# Step 1: Check Prerequisites
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "DistriSchool - Setup Development Environment"
Write-Info "======================================"
Write-Info ""

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
# Step 2: Check/Start Minikube
# ====================================
Write-Info ""
Write-Info "Verificando status do Minikube..."

$minikubeStatus = minikube status --format='{{.Host}}' 2>&1

if ($minikubeStatus -ne "Running") {
    Write-Warning "⚠️  Minikube não está rodando. Iniciando Minikube..."
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
# Step 3: Configure Docker Environment
# ====================================
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
# Step 4: Build Docker Images
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
# Step 5: Apply Kubernetes Manifests
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Aplicando Manifestos Kubernetes"
Write-Info "======================================"
Write-Info ""

# Function to apply Kubernetes manifests
function Apply-K8sManifests {
    param(
        [string]$ServiceName,
        [string]$ManifestPath,
        [string]$Emoji
    )
    
    Write-Info ""
    Write-Info "$Emoji Aplicando manifests do $ServiceName..."
    
    if (-not (Test-Path $ManifestPath)) {
        Write-Warning "⚠️  Pasta de manifests não encontrada: $ManifestPath"
        return $false
    }
    
    try {
        kubectl apply -f $ManifestPath
        if ($LASTEXITCODE -ne 0) {
            throw "kubectl apply falhou"
        }
        Write-Success "✅ Manifests do $ServiceName aplicados com sucesso!"
        return $true
    }
    catch {
        Write-Error "❌ Erro ao aplicar manifests do $ServiceName : $_"
        return $false
    }
}

# Apply Infrastructure manifests first
Write-Info "🗄️  Aplicando Infraestrutura (PostgreSQL e RabbitMQ)..."

$infraSuccess = $true

if (-not (Apply-K8sManifests -ServiceName "PostgreSQL" -ManifestPath ".\k8s-manifests\postgres" -Emoji "🐘")) {
    $infraSuccess = $false
}

if (-not (Apply-K8sManifests -ServiceName "RabbitMQ" -ManifestPath ".\k8s-manifests\rabbitmq" -Emoji "🐰")) {
    $infraSuccess = $false
}

if ($infraSuccess) {
    Write-Info ""
    Write-Info "⏳ Aguardando infraestrutura ficar pronta (30 segundos)..."
    Start-Sleep -Seconds 30
}

# Apply Backend Services
Write-Info ""
Write-Info "🎓 Aplicando Serviços de Backend..."

$servicesSuccess = $true

if (-not (Apply-K8sManifests -ServiceName "Professor Service" -ManifestPath ".\k8s-manifests\professor-service" -Emoji "📚")) {
    $servicesSuccess = $false
}

if (-not (Apply-K8sManifests -ServiceName "Aluno Service" -ManifestPath ".\k8s-manifests\aluno-service" -Emoji "👨‍🎓")) {
    $servicesSuccess = $false
}

if (-not (Apply-K8sManifests -ServiceName "User Service" -ManifestPath ".\k8s-manifests\user-service" -Emoji "👤")) {
    $servicesSuccess = $false
}

if ($servicesSuccess) {
    Write-Info ""
    Write-Info "⏳ Aguardando serviços de backend ficarem prontos (30 segundos)..."
    Start-Sleep -Seconds 30
}

# Apply API Gateway and Frontend
Write-Info ""
Write-Info "🌐 Aplicando API Gateway e Frontend..."

$frontendSuccess = $true

if (-not (Apply-K8sManifests -ServiceName "API Gateway" -ManifestPath ".\k8s-manifests\api-gateway" -Emoji "🌐")) {
    $frontendSuccess = $false
}

if (-not (Apply-K8sManifests -ServiceName "Frontend" -ManifestPath ".\k8s-manifests\frontend" -Emoji "💻")) {
    $frontendSuccess = $false
}

# ====================================
# Step 6: Final Status and Instructions
# ====================================
Write-Info ""
Write-Info "======================================"
Write-Info "Status Final"
Write-Info "======================================"
Write-Info ""

Write-Info "Aguardando pods iniciarem (10 segundos)..."
Start-Sleep -Seconds 10

Write-Success "✅ Setup completado!"
Write-Info ""

# Display pods status
Write-Info "Status dos Pods:"
kubectl get pods -A

Write-Info ""
Write-Info "======================================"
Write-Info "Próximos Passos"
Write-Info "======================================"
Write-Info ""

Write-Info "1. Verifique se todos os pods estão rodando:"
Write-Host "   kubectl get pods -A" -ForegroundColor Yellow
Write-Info ""

Write-Info "2. Para obter a URL do Frontend:"
Write-Host "   minikube service frontend-service --url" -ForegroundColor Yellow
Write-Info ""

Write-Info "3. Para obter a URL do API Gateway:"
Write-Host "   minikube service api-gateway-service --url" -ForegroundColor Yellow
Write-Info ""

Write-Info "4. Para obter a URL do RabbitMQ Management Console:"
Write-Host "   minikube service rabbitmq-service --url" -ForegroundColor Yellow
Write-Info "   (Use a porta 15672, usuário: guest, senha: guest)"
Write-Info ""

Write-Info "5. Para abrir o Frontend diretamente no navegador:"
Write-Host "   minikube service frontend-service" -ForegroundColor Yellow
Write-Info ""

Write-Info "6. Para verificar logs de um pod específico:"
Write-Host "   kubectl logs <nome-do-pod>" -ForegroundColor Yellow
Write-Info ""

Write-Info "7. Para verificar logs em tempo real:"
Write-Host "   kubectl logs -f <nome-do-pod>" -ForegroundColor Yellow
Write-Info ""

Write-Success "======================================"
Write-Success "Ambiente DistriSchool está pronto!"
Write-Success "======================================"
Write-Info ""

Write-Info "Para mais informações, consulte o arquivo TESTING_MINIKUBE.md"
