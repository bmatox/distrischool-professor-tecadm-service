# Scripts PowerShell - DistriSchool

Este documento descreve os dois scripts PowerShell criados para gerenciar o ambiente DistriSchool de forma limpa e automática.

## 📋 Scripts Disponíveis

### 1. `clean-setup.ps1` - Script de Limpeza

**Objetivo:** Limpar completamente o ambiente DistriSchool, deletando o cluster Minikube e opcionalmente as imagens Docker.

**Características:**
- ✅ Verificação de pré-requisitos (minikube, kubectl, docker)
- ✅ Confirmação do usuário antes de ações destrutivas
- ✅ Remoção de todos os recursos Kubernetes (Ingress, Frontend, Services, Infrastructure)
- ✅ Deleção completa do cluster Minikube
- ✅ Limpeza opcional das imagens Docker do DistriSchool
- ✅ Tratamento gracioso de recursos não encontrados
- ✅ Mensagens coloridas e informativas

**Como usar:**
```powershell
# Execute o script
.\clean-setup.ps1

# O script pedirá confirmação:
# - Primeira confirmação: para deletar Minikube
# - Segunda confirmação: para remover imagens Docker (opcional)
```

**Fluxo do script:**
1. Verifica se minikube, kubectl e docker estão instalados
2. Solicita confirmação do usuário
3. Se Minikube estiver rodando:
   - Remove Ingress
   - Remove Frontend
   - Remove API Gateway e Backend Services
   - Remove Infrastructure (PostgreSQL, RabbitMQ)
4. Deleta o cluster Minikube completamente
5. Opcionalmente remove imagens Docker do DistriSchool

**Quando usar:**
- Quando quiser resetar o ambiente completamente
- Antes de fazer um novo deploy do zero
- Para liberar recursos do sistema
- Para resolver problemas de estado inconsistente

---

### 2. `full-deploy.ps1` - Script de Deploy Completo

**Objetivo:** Executar o deploy completo do ambiente DistriSchool, incluindo configuração do Minikube, build das imagens e deploy de todos os serviços.

**Características:**
- ✅ Verificação de pré-requisitos
- ✅ Configuração automática do Minikube (4 CPUs, 8GB RAM, driver docker)
- ✅ Habilitação do Ingress addon
- ✅ Configuração do Docker para usar o daemon do Minikube
- ✅ Build de todas as imagens Docker
- ✅ Deploy ordenado de todos os componentes
- ✅ Espera inteligente por recursos ficarem prontos
- ✅ Instruções de acesso ao final
- ✅ Mensagens coloridas e informativas

**Como usar:**
```powershell
# Execute o script
.\full-deploy.ps1

# O script executará automaticamente todos os passos
# Tempo estimado: 10-15 minutos (dependendo do hardware)
```

**Fluxo do script:**
1. **Verificação de Pré-requisitos**
   - Verifica minikube, kubectl e docker

2. **Configuração do Minikube**
   - Inicia Minikube com:
     - CPUs: 4
     - Memória: 8192 MB (8 GB)
     - Driver: docker
   - Habilita o addon Ingress

3. **Configuração do Docker**
   - Configura o ambiente Docker para usar o daemon do Minikube

4. **Build das Imagens Docker**
   - Professor Service
   - Aluno Service
   - User Service
   - API Gateway
   - Frontend

5. **Deploy da Infraestrutura**
   - PostgreSQL
   - RabbitMQ
   - Aguarda pods ficarem prontos (120s timeout)

6. **Deploy dos Backend Services**
   - Professor Service
   - Aluno Service
   - User Service
   - API Gateway
   - Aguarda pods ficarem prontos (120s timeout)

7. **Deploy do Frontend**
   - Frontend React
   - Aguarda pod ficar pronto (120s timeout)

8. **Deploy do Ingress**
   - Configura roteamento HTTP

9. **Instruções de Acesso**
   - Mostra status dos pods
   - Fornece instruções para configurar o arquivo hosts
   - Lista URLs de acesso
   - Mostra comandos úteis

**Quando usar:**
- Primeira vez configurando o ambiente
- Após executar o `clean-setup.ps1`
- Quando quiser garantir um ambiente limpo e consistente
- Para demonstrações ou testes

---

## 🚀 Fluxo de Trabalho Típico

### Primeira Vez

```powershell
# 1. Clone o repositório
git clone <URL_DO_REPOSITORIO>
cd distrischool-professor-tecadm-service

# 2. Execute o deploy completo
.\full-deploy.ps1

# 3. Configure o arquivo hosts (como Administrador)
$minikubeIp = minikube ip
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$minikubeIp distrischool.local"

# 4. Acesse o sistema
Start-Process "http://distrischool.local"
```

### Resetar o Ambiente

```powershell
# 1. Limpar o ambiente atual
.\clean-setup.ps1
# Confirme quando solicitado

# 2. Deploy novamente
.\full-deploy.ps1
```

### Desenvolvimento Diário

```powershell
# Ao iniciar o trabalho (se Minikube foi parado)
minikube start

# Ao finalizar o trabalho (para liberar recursos)
minikube stop

# Se quiser deletar tudo
.\clean-setup.ps1
```

---

## 📊 Recursos Necessários

### Requisitos Mínimos
- **RAM:** 8 GB disponível para o Minikube
- **CPU:** 4 cores disponíveis
- **Disco:** ~10 GB para imagens e volumes
- **Sistema:** Windows 10/11 com Docker Desktop

### Requisitos Recomendados
- **RAM:** 16 GB total (8 GB para Minikube)
- **CPU:** 8 cores (4 para Minikube)
- **Disco:** SSD com 20 GB disponível

---

## 🔧 Troubleshooting

### Problema: "Minikube não inicia"

```powershell
# Verifique se o Docker Desktop está rodando
docker ps

# Se o Docker não estiver rodando, inicie-o primeiro
# Então tente novamente:
.\full-deploy.ps1
```

### Problema: "Build das imagens falha"

```powershell
# Verifique se o Docker está usando o daemon do Minikube
minikube docker-env --shell powershell | Invoke-Expression

# Liste as imagens
docker images

# Se necessário, limpe imagens antigas
docker system prune -a
```

### Problema: "Pods não ficam prontos"

```powershell
# Verifique os logs dos pods
kubectl get pods -A
kubectl logs <nome-do-pod>
kubectl describe pod <nome-do-pod>

# Se necessário, delete e recrie
kubectl delete pod <nome-do-pod>
```

### Problema: "Frontend não carrega"

```powershell
# Verifique se o Ingress está rodando
kubectl get ingress

# Verifique se o hosts está configurado
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "distrischool.local"

# Se não estiver, adicione:
$minikubeIp = minikube ip
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$minikubeIp distrischool.local"
```

---

## 📝 Comandos Úteis

### Gerenciar Minikube

```powershell
# Ver status
minikube status

# Iniciar (se parado)
minikube start

# Parar (libera recursos)
minikube stop

# Deletar (remove tudo)
minikube delete

# Ver IP
minikube ip

# Dashboard web
minikube dashboard
```

### Gerenciar Pods

```powershell
# Listar todos os pods
kubectl get pods -A

# Ver logs de um pod
kubectl logs <nome-do-pod>

# Ver logs em tempo real
kubectl logs -f <nome-do-pod>

# Descrever um pod (para debug)
kubectl describe pod <nome-do-pod>

# Deletar um pod (será recriado)
kubectl delete pod <nome-do-pod>
```

### Acessar Serviços

```powershell
# Frontend
Start-Process "http://distrischool.local"

# API
Start-Process "http://distrischool.local/api/v1/professores"

# RabbitMQ Management (obter URL)
minikube service rabbitmq-service --url
# Acesse a porta 15672 (usuário: guest, senha: guest)
```

---

## 🎯 Diferenças dos Scripts Antigos

### Comparação com `setup-dev-env.ps1`

| Recurso | setup-dev-env.ps1 | full-deploy.ps1 |
|---------|-------------------|-----------------|
| Configuração Minikube | Só verifica/inicia | **Configura CPU/RAM** |
| Ingress | Não configura | **Configura automaticamente** |
| Mensagens | Básicas | **Mais detalhadas e coloridas** |
| Tratamento de erros | Básico | **Mais robusto** |
| Instruções finais | Limitadas | **Completas com URLs** |

### Comparação com `deploy-with-ingress.ps1`

| Recurso | deploy-with-ingress.ps1 | full-deploy.ps1 |
|---------|------------------------|-----------------|
| Minikube | Assume rodando | **Inicia e configura** |
| Build | Básico | **Com tratamento de erros** |
| Deploy | Simples | **Com wait/timeout** |
| Documentação | Mínima | **Extensa** |

### Novo: `clean-setup.ps1`

Este script não existia antes! Ele preenche uma lacuna importante:
- **Antes:** Era necessário executar comandos manualmente para limpar
- **Agora:** Um único script limpa tudo com segurança

---

## 📚 Documentação Relacionada

- [README.md](./README.md) - Visão geral do projeto
- [INGRESS_DEPLOYMENT_GUIDE.md](./INGRESS_DEPLOYMENT_GUIDE.md) - Guia de deploy com Ingress
- [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) - Guia de testes no Minikube
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Guia de testes funcionais

---

## 🤝 Contribuindo

Se encontrar problemas ou tiver sugestões de melhorias para os scripts, por favor:
1. Abra uma issue descrevendo o problema ou sugestão
2. Ou envie um Pull Request com as melhorias

---

## 📄 Licença

Este projeto está sob a licença MIT.
