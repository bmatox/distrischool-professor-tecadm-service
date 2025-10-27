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
Write-Host "⏳ Aguardando infraestrutura..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s

# 4. Deploy serviços
Write-Host "⚙️ Fazendo deploy dos serviços..." -ForegroundColor Yellow
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/
kubectl apply -f k8s-manifests/api-gateway/
Write-Host "⏳ Aguardando serviços..." -ForegroundColor Cyan
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
Write-Host ""
Write-Host "📝 Para testar, execute: curl http://distrischool.local/api/v1/professores" -ForegroundColor Gray
