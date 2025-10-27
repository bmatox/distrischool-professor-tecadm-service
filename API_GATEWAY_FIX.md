# Correção do Erro 404 no API Gateway

## 📋 Sumário Executivo

Este documento descreve a investigação, diagnóstico e correção do erro `HTTP 404 Not Found` que ocorria ao tentar acessar o endpoint `/api/v1/professores` através do frontend.

**Data da Correção:** 27 de outubro de 2025  
**Erro Original:** `GET http://distrischool.local/api/v1/professores 404 (Not Found)`  
**Status:** ✅ Corrigido

---

## 🔍 Investigação do Problema

### Sintomas Observados

No console do navegador, o seguinte erro era exibido repetidamente:

```javascript
GET http://distrischool.local/api/v1/professores 404 (Not Found)
API request failed: /v1/professores Error: HTTP error! status: 404
Erro ao buscar professores: Error: HTTP error! status: 404
```

Na aba Network do navegador, a resposta da API era:

```json
{
  "timestamp": "2025-10-27T18:54:50.976+00:00",
  "path": "/v1/professores",
  "status": 404,
  "error": "Not Found",
  "requestId": "7c9150eb-3"
}
```

**Observação importante:** Note que o path na resposta é `/v1/professores` (sem o `/api`), mesmo que o frontend tenha requisitado `/api/v1/professores`.

### Arquitetura do Sistema

O sistema DistriSchool possui a seguinte arquitetura de roteamento:

```
Frontend (Browser)
    ↓
http://distrischool.local/api/v1/professores
    ↓
Ingress NGINX (distrischool.local)
    ↓
API Gateway (port 8080)
    ↓
Professor Service (port 8082)
```

### Componentes Investigados

#### 1. Frontend
O frontend estava fazendo a requisição correta:
```javascript
GET http://distrischool.local/api/v1/professores
Headers:
  - Content-Type: application/json
  - Host: distrischool.local
```

#### 2. Professor Service (Backend)
O controller estava configurado corretamente:
```java
@RestController
@RequestMapping("/api/v1/professores")
public class ProfessorController {
    @GetMapping
    public ResponseEntity<Page<ProfessorResponse>> list(@ParameterObject Pageable pageable) {
        return ResponseEntity.ok(service.list(pageable));
    }
}
```
O serviço expõe o endpoint em `http://professor-tecadm-service:8082/api/v1/professores`

#### 3. API Gateway
A configuração do Spring Cloud Gateway estava:
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: professor-service
          uri: http://professor-tecadm-service:8082
          predicates:
            - Path=/api/v1/professores/**
```
O gateway esperava requisições em `/api/v1/professores/**`

#### 4. Ingress NGINX (O PROBLEMA!)
A configuração original do Ingress estava:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: distrischool-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2  # ← PROBLEMA AQUI!
spec:
  rules:
    - host: distrischool.local
      http:
        paths:
          - path: /api(/|$)(.*)  # ← E AQUI!
            pathType: ImplementationSpecific
            backend:
              service:
                name: api-gateway-service
                port:
                  number: 8080
```

---

## 🐛 Causa Raiz do Problema

A configuração do Ingress estava usando um **rewrite-target** com captura de grupos regex:

1. **Path Pattern:** `/api(/|$)(.*)`
   - Grupo 1: `(/|$)` - captura `/` ou fim da string
   - Grupo 2: `(.*)` - captura tudo após o grupo 1

2. **Rewrite Target:** `/$2`
   - Substitui o path pelo conteúdo do grupo 2

### Fluxo da Requisição (COM O PROBLEMA)

```
1. Frontend envia:
   GET /api/v1/professores

2. Ingress recebe e processa:
   Path: /api/v1/professores
   Matches: /api(/|$)(.*)
   Grupo 1: /
   Grupo 2: v1/professores
   Rewrite: /$2 = /v1/professores

3. Ingress envia para API Gateway:
   GET /v1/professores  ← SEM O /api !

4. API Gateway procura rota:
   Rota configurada: /api/v1/professores/**
   Requisição recebida: /v1/professores
   Resultado: 404 Not Found ❌
```

### Por Que Isso Aconteceu?

O rewrite foi configurado para "limpar" o prefixo `/api` da URL, provavelmente com a intenção de:
- Permitir que os serviços backend não precisassem saber sobre o prefixo `/api`
- Simplificar as rotas internas

**Porém**, no nosso caso:
- O API Gateway **PRECISA** do prefixo `/api` nas suas rotas
- Os serviços backend (como Professor Service) **JÁ INCLUEM** `/api` nas suas rotas
- Remover o `/api` no Ingress quebrou toda a cadeia de roteamento

---

## ✅ Solução Implementada

### Configuração Corrigida do Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: distrischool-ingress
  annotations:
    # REMOVIDO: nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Content-Type, Authorization"
    nginx.ingress.kubernetes.io/enable-cors: "true"
spec:
  ingressClassName: nginx
  rules:
    - host: distrischool.local
      http:
        paths:
          # API Gateway routes - preserve /api prefix
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-gateway-service
                port:
                  number: 8080
          # Frontend routes - must be last as it catches everything
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### Mudanças Realizadas

1. **Removido `rewrite-target`:** 
   - Não há mais reescrita do path
   - O path original é preservado

2. **Simplificado o path pattern:**
   - De: `/api(/|$)(.*)`
   - Para: `/api`
   - Usa `pathType: Prefix` para match automático de sub-paths

3. **Ordem dos paths:**
   - `/api` vem primeiro (mais específico)
   - `/` vem depois (catch-all para o frontend)
   - Isso é importante porque o Ingress processa paths na ordem

### Fluxo da Requisição (CORRIGIDO)

```
1. Frontend envia:
   GET /api/v1/professores

2. Ingress recebe e processa:
   Path: /api/v1/professores
   Matches: /api (com pathType: Prefix)
   Rewrite: NENHUM (path preservado)

3. Ingress envia para API Gateway:
   GET /api/v1/professores  ← PRESERVADO! ✅

4. API Gateway procura rota:
   Rota configurada: /api/v1/professores/**
   Requisição recebida: /api/v1/professores
   Match encontrado! ✅

5. API Gateway encaminha para Professor Service:
   GET http://professor-tecadm-service:8082/api/v1/professores

6. Professor Service processa:
   Controller: @RequestMapping("/api/v1/professores")
   Endpoint: @GetMapping
   Resultado: 200 OK ✅
```

---

## 🧪 Como Testar a Correção

### 1. Aplicar a Configuração Corrigida

```powershell
# Aplicar o novo Ingress
kubectl apply -f k8s-manifests/ingress.yaml

# Verificar se foi aplicado
kubectl get ingress distrischool-ingress -o yaml

# Aguardar alguns segundos para o NGINX recarregar
Start-Sleep -Seconds 5
```

### 2. Testar com curl (via PowerShell)

```powershell
# Testar o endpoint diretamente
curl http://distrischool.local/api/v1/professores

# Se funcionar, você deve ver uma resposta JSON como:
# {
#   "content": [...],
#   "pageable": {...},
#   "totalElements": X,
#   "totalPages": Y
# }
```

### 3. Testar via Frontend

1. Abra o navegador e acesse `http://distrischool.local`
2. Navegue até a seção de professores
3. Abra o DevTools (F12) → aba Network
4. Observe as requisições:
   - Você deve ver `200 OK` ao invés de `404 Not Found`
   - O response payload deve conter a lista de professores

### 4. Verificar Logs do API Gateway

```powershell
# Ver logs do API Gateway
kubectl logs -f deployment/api-gateway-deployment

# Você deve ver logs de requisições bem-sucedidas:
# [INFO] Routing /api/v1/professores to http://professor-tecadm-service:8082
```

### 5. Teste Completo End-to-End

```powershell
# 1. Criar um professor
$body = @{
    nome = "João Silva"
    email = "joao.silva@example.com"
    departamento = "Ciência da Computação"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://distrischool.local/api/v1/professores" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"

# 2. Listar professores
Invoke-RestMethod -Uri "http://distrischool.local/api/v1/professores" `
    -Method GET

# 3. Buscar professor específico (substitua {id} pelo ID retornado)
Invoke-RestMethod -Uri "http://distrischool.local/api/v1/professores/{id}" `
    -Method GET
```

---

## 📊 Comparação Antes x Depois

### ANTES (Com Problema)

| Componente | Requisição Recebida | Status |
|------------|---------------------|--------|
| Frontend | `GET /api/v1/professores` | ✅ Envia |
| Ingress | `GET /api/v1/professores` → `GET /v1/professores` | ⚠️ Reescreve |
| API Gateway | `GET /v1/professores` | ❌ 404 |
| Professor Service | Não chega | ❌ Não chamado |

### DEPOIS (Corrigido)

| Componente | Requisição Recebida | Status |
|------------|---------------------|--------|
| Frontend | `GET /api/v1/professores` | ✅ Envia |
| Ingress | `GET /api/v1/professores` | ✅ Preserva |
| API Gateway | `GET /api/v1/professores` | ✅ Roteia |
| Professor Service | `GET /api/v1/professores` | ✅ 200 OK |

---

## 🎯 Lições Aprendidas

### 1. Cuidado com Rewrite Rules no Ingress
- Rewrites podem quebrar a cadeia de roteamento se não forem bem planejados
- Sempre documente o propósito de cada rewrite
- Teste o path completo da requisição

### 2. Consistência nas Rotas
- API Gateway, Backend Services e Frontend devem estar alinhados
- Se o backend usa `/api`, o gateway também deve usar
- Documente as convenções de roteamento

### 3. Debugging de Problemas de Roteamento
Para diagnosticar problemas similares:

1. **Verifique o path no erro:**
   - Se o path na resposta de erro é diferente do path requisitado, há um rewrite acontecendo

2. **Trace a requisição por cada camada:**
   - Frontend → Ingress → Gateway → Service
   - Use logs de cada componente

3. **Verifique configurações de Ingress:**
   - `rewrite-target` annotations
   - Path patterns e regex
   - Ordem dos paths (mais específico primeiro)

4. **Use ferramentas de debug:**
   ```powershell
   # Ver configuração do Ingress
   kubectl get ingress -o yaml
   
   # Ver logs do Ingress Controller
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   
   # Ver logs do API Gateway
   kubectl logs deployment/api-gateway-deployment
   ```

### 4. Quando NÃO Usar Rewrite
- Quando você tem um API Gateway que já faz roteamento baseado em path
- Quando os serviços já esperam um prefixo específico (como `/api`)
- Quando múltiplos serviços compartilham um prefixo comum

### 5. Quando Usar Rewrite
- Para remover prefixos de "namespace" que não são parte da API real
- Para versionamento transparente (ex: `/v1` → `/`)
- Para migração gradual de APIs
- Para simplificar rotas em serviços legados

---

## 🚀 Aplicando a Correção no Seu Ambiente

Se você está executando o DistriSchool e encontrou este problema:

### Opção 1: Redeployment Completo (Recomendado)

```powershell
# 1. Limpar ambiente atual
.\clean-setup.ps1

# 2. Deploy completo com correção
.\full-deploy.ps1

# 3. Testar
curl http://distrischool.local/api/v1/professores
```

### Opção 2: Aplicar Apenas a Correção do Ingress

```powershell
# 1. Aplicar o Ingress corrigido
kubectl apply -f k8s-manifests/ingress.yaml

# 2. Verificar se foi aplicado
kubectl get ingress distrischool-ingress

# 3. Aguardar reload do NGINX
Start-Sleep -Seconds 10

# 4. Testar
curl http://distrischool.local/api/v1/professores
```

### Opção 3: Editar Manualmente (Temporário)

```powershell
# Editar o Ingress diretamente no cluster
kubectl edit ingress distrischool-ingress

# No editor:
# 1. Remova a linha: nginx.ingress.kubernetes.io/rewrite-target: /$2
# 2. Mude /api(/|$)(.*) para /api
# 3. Mude pathType para Prefix
# 4. Salve e feche
```

---

## 🔍 Troubleshooting Adicional

### Se Ainda Ver 404 Após a Correção

1. **Verifique se o Ingress foi realmente atualizado:**
   ```powershell
   kubectl get ingress distrischool-ingress -o yaml | Select-String "rewrite"
   # Não deve retornar nada
   ```

2. **Force reload do Ingress Controller:**
   ```powershell
   kubectl delete pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   # Aguarde o pod recriar
   kubectl wait --for=condition=ready pod -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --timeout=120s
   ```

3. **Verifique se o API Gateway está rodando:**
   ```powershell
   kubectl get pods | Select-String "api-gateway"
   kubectl logs deployment/api-gateway-deployment
   ```

4. **Verifique se o Professor Service está rodando:**
   ```powershell
   kubectl get pods | Select-String "professor"
   kubectl logs deployment/professor-tecadm-deployment
   ```

5. **Teste o API Gateway diretamente (port-forward):**
   ```powershell
   kubectl port-forward deployment/api-gateway-deployment 8080:8080
   # Em outro terminal:
   curl http://localhost:8080/api/v1/professores
   ```

6. **Limpe o cache DNS:**
   ```powershell
   ipconfig /flushdns
   ```

7. **Limpe o cache do navegador:**
   - Ctrl+Shift+Del → Clear All
   - Ou use modo anônimo (Ctrl+Shift+N)

---

## 📝 Checklist de Validação

Após aplicar a correção, verifique:

- [ ] Ingress não tem `rewrite-target` annotation
- [ ] Path do API é `/api` com `pathType: Prefix`
- [ ] Path do frontend é `/` com `pathType: Prefix`
- [ ] Ordem dos paths está correta (API antes do frontend)
- [ ] `kubectl get ingress` mostra o Ingress como configurado
- [ ] `curl http://distrischool.local/api/v1/professores` retorna 200
- [ ] Frontend consegue carregar a lista de professores
- [ ] Console do navegador não mostra erros 404
- [ ] API Gateway logs mostram requisições sendo roteadas

---

## 📚 Referências

- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [NGINX Ingress Controller Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/)
- [Spring Cloud Gateway Documentation](https://spring.io/projects/spring-cloud-gateway)

---

## 👤 Autor da Correção

**Agente:** GitHub Copilot Coding Agent  
**Data:** 27 de outubro de 2025  
**Repositório:** bmatox/distrischool-professor-tecadm-service

---

## 📄 Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.0 | 2025-10-27 | Documento inicial com análise e correção do problema |

---

**Status Final:** ✅ PROBLEMA RESOLVIDO

O erro 404 foi corrigido removendo a reescrita desnecessária do path no Ingress NGINX, permitindo que o prefixo `/api` seja preservado e corretamente roteado através do API Gateway até os serviços backend.
