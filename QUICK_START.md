# 🚀 DistriSchool - Quick Start Guide

## Para Usuários Windows (Recomendado)

### 🆕 Método Mais Simples - Novos Scripts PowerShell

#### Primeira Vez - Deploy Completo

```powershell
# 1. Clone o repositório
git clone https://github.com/bmatox/distrischool-professor-tecadm-service.git
cd distrischool-professor-tecadm-service

# 2. Execute o deploy completo (tudo em um comando!)
.\full-deploy.ps1

# 3. Configure o arquivo hosts (executar como Administrador)
$minikubeIp = minikube ip
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$minikubeIp distrischool.local"

# 4. Acesse o DistriSchool
Start-Process "http://distrischool.local"
```

**Pronto!** O ambiente está completo e funcionando! 🎉

---

#### Resetar o Ambiente

```powershell
# Limpar tudo (deletar Minikube e recursos)
.\clean-setup.ps1

# Deploy novamente
.\full-deploy.ps1
```

---

#### Uso Diário

```powershell
# Ao iniciar o trabalho (se parou o Minikube)
minikube start

# Verificar status
kubectl get pods -A

# Acessar o sistema
Start-Process "http://distrischool.local"

# Ao finalizar o trabalho (libera recursos)
minikube stop

# Para deletar completamente
.\clean-setup.ps1
```

---

## 📋 Pré-requisitos

Antes de executar os scripts, certifique-se de ter instalado:

- ✅ [Docker Desktop](https://www.docker.com/products/docker-desktop) (rodando)
- ✅ [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- ✅ [kubectl](https://kubernetes.io/docs/tasks/tools/)
- ✅ PowerShell 5.1+ (já vem com Windows)

**Requisitos de Hardware:**
- CPU: 4 cores disponíveis
- RAM: 8 GB disponível
- Disco: ~10 GB livre

---

## 🔧 Comandos Úteis

### Verificar Status

```powershell
# Status do Minikube
minikube status

# Status dos Pods
kubectl get pods -A

# Status dos Services
kubectl get services -A
```

### Ver Logs

```powershell
# Listar pods
kubectl get pods

# Ver logs de um pod específico
kubectl logs <pod-name>
# Exemplo: kubectl logs professor-tecadm-service-7d8f9b5c6d-xyz12

# Ver logs em tempo real
kubectl logs -f <pod-name>
# Exemplo: kubectl logs -f professor-tecadm-service-7d8f9b5c6d-xyz12
```

### Acessar Serviços

```powershell
# Frontend
Start-Process "http://distrischool.local"

# API
Invoke-WebRequest "http://distrischool.local/api/v1/professores"

# RabbitMQ Management
minikube service rabbitmq-service --url
# Acesse a porta 15672: usuário=guest, senha=guest

# Dashboard do Kubernetes
minikube dashboard
```

---

## ❓ Problemas Comuns

### Minikube não inicia

```powershell
# Certifique-se que o Docker Desktop está rodando
docker ps

# Se o erro persistir, delete e recrie
minikube delete
minikube start --cpus=4 --memory=8192 --driver=docker
```

### Frontend não carrega

```powershell
# Verifique se o hosts está configurado
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "distrischool.local"

# Se não estiver, adicione
$minikubeIp = minikube ip
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$minikubeIp distrischool.local"
```

### Pods não ficam prontos

```powershell
# Veja o que está acontecendo
kubectl get pods -A
kubectl describe pod <pod-name>
kubectl logs <pod-name>
# Exemplo: kubectl logs professor-tecadm-service-7d8f9b5c6d-xyz12

# Se necessário, reinicie o deploy
.\clean-setup.ps1
.\full-deploy.ps1
```

---

## 📚 Documentação Completa

Para informações detalhadas, consulte:

- **[POWERSHELL_SCRIPTS_GUIDE.md](./POWERSHELL_SCRIPTS_GUIDE.md)** - Guia completo dos scripts
- **[README.md](./README.md)** - Documentação geral do projeto
- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Guia de testes funcionais

---

## 🎯 O que cada script faz?

### `full-deploy.ps1`
1. Verifica pré-requisitos
2. Inicia e configura o Minikube (4 CPUs, 8GB RAM)
3. Habilita Ingress
4. Constrói todas as imagens Docker
5. Faz deploy de toda a infraestrutura
6. Faz deploy de todos os serviços
7. Faz deploy do frontend
8. Configura o Ingress
9. Mostra instruções de acesso

**Tempo estimado:** 10-15 minutos

### `clean-setup.ps1`
1. Pede confirmação
2. Remove todos os recursos do Kubernetes
3. Deleta o cluster Minikube
4. Opcionalmente remove imagens Docker
5. Mostra instruções de próximos passos

**Tempo estimado:** 2-3 minutos

---

## 💡 Dicas

- **Primeira vez:** Use `full-deploy.ps1` - faz tudo automaticamente
- **Problemas:** Use `clean-setup.ps1` seguido de `full-deploy.ps1`
- **Recursos:** Use `minikube stop` para liberar CPU/RAM quando não estiver usando
- **Logs:** Use `kubectl logs -f <pod>` para ver logs em tempo real
- **Dashboard:** Use `minikube dashboard` para interface visual

---

## ✨ Benefícios

Estes scripts foram criados para simplificar o gerenciamento do ambiente DistriSchool. Eles substituem processos manuais complexos e tornam o desenvolvimento muito mais eficiente!

**Antes:** Vários comandos manuais, configuração complexa e propensa a erros
**Agora:** Um comando para deploy completo, um comando para limpar - simples e confiável

Aproveite! 🚀
