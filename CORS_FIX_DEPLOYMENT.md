# Correção CORS - Instruções de Deploy e Verificação

## 📋 Resumo da Correção

O problema de CORS persistente foi causado por uma configuração incompatível no API Gateway:
- **Problema**: `allow-credentials: true` + `allowed-origins: "*"` não é permitido pelos navegadores
- **Solução**: Alterado para `allow-credentials: false` e uso de `addAllowedOriginPattern()` 

## 🔧 Arquivos Modificados

1. **api-gateway/src/main/resources/application.yml**
   - `allow-credentials: true` → `allow-credentials: false`

2. **api-gateway/src/main/java/br/com/distrischool/gateway/CorsGlobalConfig.java**
   - Uso de `addAllowedOriginPattern()` em vez de `addAllowedOrigin()`
   - Adicionado caching de preflight com `maxAge(3600L)`

## 🚀 Como Aplicar a Correção

### Opção 1: Rebuild Completo (Recomendado)

```bash
# 1. Navegue até o diretório do projeto
cd /path/to/distrischool-professor-tecadm-service

# 2. Rebuild da imagem Docker do API Gateway
docker build -t api-gateway:latest ./api-gateway

# 3. Se estiver usando um registry, faça o push
docker tag api-gateway:latest seu-registry/api-gateway:latest
docker push seu-registry/api-gateway:latest

# 4. Reinicie o deployment no Kubernetes
kubectl rollout restart deployment/api-gateway -n distrischool

# 5. Aguarde o deployment completar
kubectl rollout status deployment/api-gateway -n distrischool
```

### Opção 2: Usando o Script de Build Existente

```bash
# Se o projeto tem um script de build
./build-all.sh

# Depois aplique os deployments
./deploy-all.sh
```

## ✅ Como Verificar se a Correção Funcionou

### 1. Verificar os Logs do API Gateway

```bash
# Verificar se o pod está rodando
kubectl get pods -n distrischool | grep api-gateway

# Ver os logs do API Gateway
kubectl logs -f deployment/api-gateway -n distrischool
```

**O que procurar nos logs:**
- O serviço deve iniciar sem erros
- Procure por mensagens relacionadas a CORS ou CorsWebFilter

### 2. Testar via Console do Navegador

1. **Abra o Frontend** em http://127.0.0.1:60002
2. **Abra as DevTools** (F12)
3. **Vá para a aba Console**
4. **Tente fazer uma requisição** (por exemplo, buscar professores)

**Antes da correção (erro esperado):**
```
Access to fetch at 'http://127.0.0.1:54717/api/v1/professores' from origin 'http://127.0.0.1:60002' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

**Depois da correção (sucesso esperado):**
- Nenhum erro de CORS no console
- A requisição retorna com dados ou erro de API (não erro de CORS)

### 3. Verificar Headers HTTP na Aba Network

1. **Abra DevTools** → **Aba Network**
2. **Faça uma requisição** ao API Gateway
3. **Clique na requisição** e veja os **Response Headers**

**Headers esperados:**
```
Access-Control-Allow-Origin: http://127.0.0.1:60002
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: *
Access-Control-Max-Age: 3600
```

### 4. Testar Requisição OPTIONS (Preflight)

Abra o console do navegador e execute:

```javascript
fetch('http://127.0.0.1:54717/api/v1/professores', {
    method: 'OPTIONS',
    headers: {
        'Origin': 'http://127.0.0.1:60002',
        'Access-Control-Request-Method': 'GET'
    }
})
.then(response => {
    console.log('Preflight Status:', response.status);
    console.log('CORS Headers:', {
        'Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
        'Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
        'Allow-Headers': response.headers.get('Access-Control-Allow-Headers')
    });
})
.catch(error => console.error('Preflight Error:', error));
```

**Resultado esperado:**
- Status: 200 OK
- Headers CORS presentes na resposta

## 🔍 Troubleshooting

### Problema: Ainda vejo erros de CORS após o deploy

**Soluções:**

1. **Limpe o cache do navegador:**
   ```
   - Chrome: Ctrl+Shift+Delete → Limpar cache
   - Ou use modo anônimo (Ctrl+Shift+N)
   ```

2. **Verifique se o novo pod está rodando:**
   ```bash
   kubectl get pods -n distrischool | grep api-gateway
   # Certifique-se que o pod é recente (coluna AGE)
   ```

3. **Force um novo deployment:**
   ```bash
   kubectl delete pod -l app=api-gateway -n distrischool
   ```

4. **Verifique os ConfigMaps/Secrets:**
   ```bash
   # Se o application.yml vem de um ConfigMap
   kubectl get configmap api-gateway-config -n distrischool -o yaml
   ```

### Problema: Erro 403 Forbidden ainda persiste

**Possíveis causas:**

1. **Spring Security no backend**: Verifique se o serviço professor-tecadm-service tem configuração de Security
   ```bash
   # Ver logs do serviço de professores
   kubectl logs -f deployment/professor-tecadm-service -n distrischool
   ```

2. **Filtros adicionais no Gateway**: Verifique se há filtros customizados na configuração de rotas

### Problema: Ainda vejo `net::ERR_FAILED`

Isso pode indicar que o serviço backend não está acessível:

```bash
# Testar conectividade interna
kubectl exec -it deployment/api-gateway -n distrischool -- curl http://professor-tecadm-service:8082/api/v1/professores
```

## 📝 Notas Importantes

### Para Produção

Se você for usar esta configuração em produção, considere:

1. **Especificar origens exatas** em vez de `"*"`:
   ```yaml
   app:
     cors:
       allowed-origins: "https://distrischool.com,https://www.distrischool.com"
       allow-credentials: true  # Pode habilitar com origens específicas
   ```

2. **Restringir métodos e headers**:
   ```yaml
   app:
     cors:
       allowed-methods: "GET,POST,PUT,DELETE"
       allowed-headers: "Content-Type,Authorization"
   ```

### Para Desenvolvimento Local

A configuração atual é ideal para desenvolvimento:
- Aceita qualquer origem (`"*"`)
- Suporta portas dinâmicas do Minikube
- Métodos e headers permissivos

## 📚 Referências

- [Spring Cloud Gateway CORS Configuration](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/#cors-configuration)
- [MDN Web Docs - CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Spring Framework CORS Support](https://docs.spring.io/spring-framework/reference/web/webflux-cors.html)

## 🎯 Checklist de Verificação

- [ ] Build da nova imagem Docker completado
- [ ] Deployment reiniciado no Kubernetes
- [ ] Pod do API Gateway está rodando (status: Running)
- [ ] Logs não mostram erros relacionados a CORS
- [ ] Console do navegador não mostra erros de CORS
- [ ] Requisições OPTIONS retornam 200 OK
- [ ] Headers CORS presentes nas respostas
- [ ] Frontend consegue buscar dados da API

---

**Data da Correção**: 2025-10-27
**Versão do Spring Boot**: 3.4.5
**Versão do Spring Cloud**: 2024.0.2
