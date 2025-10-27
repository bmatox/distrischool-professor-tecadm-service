# DistriSchool - Guia de Testes Final

Este documento fornece instruções detalhadas para verificar todas as funcionalidades do sistema DistriSchool após o deploy no Minikube.

## 📋 Pré-requisitos

Antes de iniciar os testes, certifique-se de que:

1. ✅ Minikube está rodando: `minikube status`
2. ✅ Todos os pods estão saudáveis: `kubectl get pods`
3. ✅ O Ingress Controller está habilitado: `minikube addons enable ingress`

## 🚀 Setup Inicial

### 1. Habilitar Ingress no Minikube

```bash
# Habilitar o addon nginx-ingress
minikube addons enable ingress

# Verificar se o Ingress Controller está rodando
kubectl get pods -n ingress-nginx
```

### 2. Fazer Deploy da Configuração Ingress

```bash
# Aplicar o arquivo de configuração do Ingress
kubectl apply -f k8s-manifests/ingress.yaml

# Verificar o Ingress
kubectl get ingress
```

### 3. Obter o IP do Minikube

```bash
# Obter o IP do Minikube
minikube ip

# Exemplo de saída: 192.168.49.2
```

### 4. Configurar /etc/hosts (Opcional, mas Recomendado)

Para facilitar o acesso, adicione uma entrada no arquivo `/etc/hosts`:

**Linux/Mac:**
```bash
echo "$(minikube ip) distrischool.local" | sudo tee -a /etc/hosts
```

**Windows (executar como Administrador):**
```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$(minikube ip) distrischool.local"
```

## 🌐 URLs de Acesso

Após configurar o Ingress, você pode acessar os serviços através das seguintes URLs:

### Com /etc/hosts configurado:
- **Frontend:** http://distrischool.local
- **API Gateway:** http://distrischool.local/api

### Sem /etc/hosts (usando IP direto):
- **Frontend:** http://192.168.49.2 (substitua pelo IP do seu Minikube)
- **API Gateway:** http://192.168.49.2/api

### URLs NodePort (alternativa, portas dinâmicas):
```bash
# Frontend
minikube service frontend-service --url

# API Gateway
minikube service api-gateway-service --url
```

## 📝 Testes por Funcionalidade

### 1. Teste do Dashboard Principal

#### 1.1. Acessar o Dashboard

1. Abra o navegador e acesse: http://distrischool.local
2. Você deve ver a página principal do DistriSchool com:
   - ✅ Título "Bem-vindo ao DistriSchool"
   - ✅ Três cards principais: Professores, Alunos e Usuários
   - ✅ Seção de informações sobre a arquitetura

#### 1.2. Verificar Console do Navegador

1. Pressione `F12` para abrir o DevTools
2. Vá para a aba **Console**
3. **Não deve haver erros de CORS**
4. ✅ Sucesso: Console limpo ou apenas logs informativos

#### 1.3. Navegação

1. Clique em cada card do dashboard
2. Verifique se a navegação funciona sem recarregar a página
3. ✅ Sucesso: URL muda e o conteúdo é exibido instantaneamente

---

### 2. Teste do Módulo de Professores

#### 2.1. Listar Professores (GET)

1. No dashboard, clique em **"Professores"** ou acesse: http://distrischool.local/professores
2. Você deve ver:
   - ✅ Título "Gestão de Professores"
   - ✅ Botão "➕ Novo Professor"
   - ✅ Lista de professores cadastrados (ou mensagem "Nenhum professor cadastrado")

**Verificação no Console:**
```javascript
// Abra o Console (F12) e execute:
fetch('http://distrischool.local/api/v1/professores')
  .then(r => r.json())
  .then(data => console.log('Professores:', data))
```

✅ **Sucesso:** Lista de professores é retornada sem erros CORS

#### 2.2. Criar Professor (POST)

1. Na página de professores, clique em **"➕ Novo Professor"**
2. Preencha o formulário:
   - **Nome:** João da Silva
   - **Email:** joao.silva@escola.com
   - **Especialidade:** Matemática
   - **Data de Contratação:** (selecione uma data)
3. Clique em **"💾 Salvar"**
4. ✅ Sucesso: 
   - Formulário fecha automaticamente
   - Professor aparece na lista
   - Nenhum erro no console

**Teste Manual via Console:**
```javascript
fetch('http://distrischool.local/api/v1/professores', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    nome: 'Maria Santos',
    email: 'maria.santos@escola.com',
    especialidade: 'Português',
    dataContratacao: '2025-01-15'
  })
})
.then(r => r.json())
.then(data => console.log('Professor criado:', data))
```

#### 2.3. Excluir Professor (DELETE)

1. Encontre um professor na lista
2. Clique no botão **🗑️** no canto superior direito do card
3. Confirme a exclusão na janela de confirmação
4. ✅ Sucesso:
   - Professor removido da lista
   - Lista atualizada automaticamente
   - Nenhum erro no console

**Teste Manual via Console:**
```javascript
// Substitua {id} pelo ID real de um professor
fetch('http://distrischool.local/api/v1/professores/{id}', {
  method: 'DELETE'
})
.then(() => console.log('Professor excluído com sucesso'))
```

#### 2.4. Atualizar Lista

1. Clique no botão **"🔄 Atualizar Lista"** no final da página
2. ✅ Sucesso: Lista é recarregada com dados atualizados

---

### 3. Teste do Módulo de Alunos

#### 3.1. Listar Alunos (GET)

1. Acesse: http://distrischool.local/alunos
2. Você deve ver:
   - ✅ Título "Gestão de Alunos"
   - ✅ Botão "➕ Novo Aluno"
   - ✅ Lista de alunos cadastrados (ou mensagem "Nenhum aluno cadastrado")

**Verificação no Console:**
```javascript
fetch('http://distrischool.local/api/alunos')
  .then(r => r.json())
  .then(data => console.log('Alunos:', data))
```

#### 3.2. Criar Aluno (POST)

1. Na página de alunos, clique em **"➕ Novo Aluno"**
2. Preencha o formulário completo:
   
   **Dados Pessoais:**
   - **Nome:** Pedro Oliveira
   - **Matrícula:** 2025001
   - **Email:** pedro.oliveira@email.com
   - **Data de Nascimento:** 2010-03-15
   
   **Endereço:**
   - **Rua:** Rua das Flores
   - **Número:** 123
   - **Bairro:** Centro
   - **Cidade:** São Paulo
   - **Estado:** SP
   - **CEP:** 01234-567

3. Clique em **"💾 Salvar"**
4. ✅ Sucesso:
   - Formulário fecha automaticamente
   - Aluno aparece na lista com todos os dados
   - Endereço completo é exibido
   - Nenhum erro no console

**Teste Manual via Console:**
```javascript
fetch('http://distrischool.local/api/alunos', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    nome: 'Ana Costa',
    matricula: '2025002',
    email: 'ana.costa@email.com',
    dataNascimento: '2011-07-20',
    endereco: {
      rua: 'Av. Principal',
      numero: '456',
      bairro: 'Jardim América',
      cidade: 'Rio de Janeiro',
      estado: 'RJ',
      cep: '20000-000'
    }
  })
})
.then(r => r.json())
.then(data => console.log('Aluno criado:', data))
```

#### 3.3. Validar Dados do Aluno

1. Verifique se o card do aluno exibe:
   - ✅ Nome completo
   - ✅ Matrícula
   - ✅ Email
   - ✅ Data de nascimento formatada (dd/mm/aaaa)
   - ✅ Endereço completo

---

### 4. Teste do Módulo de Usuários

#### 4.1. Listar Usuários (GET)

1. Acesse: http://distrischool.local/usuarios
2. Você deve ver:
   - ✅ Título "Gestão de Usuários"
   - ✅ Lista de usuários cadastrados (ou mensagem "Nenhum usuário cadastrado")

**Verificação no Console:**
```javascript
fetch('http://distrischool.local/api/users')
  .then(r => r.json())
  .then(data => console.log('Usuários:', data))
```

#### 4.2. Validar Exibição de Usuários

1. Cada card de usuário deve exibir:
   - ✅ Nome/Username
   - ✅ Email (se disponível)
   - ✅ Função/Role (se disponível)
   - ✅ Data de criação (se disponível)

---

### 5. Testes de Integração e Fluxo Completo

#### 5.1. Fluxo Completo: Criar e Visualizar Professor

1. **Criar:** Acesse `/professores` → Clique em "➕ Novo Professor" → Preencha o formulário → Salve
2. **Listar:** Verifique se o professor aparece na lista imediatamente
3. **Persistência:** Pressione F5 para recarregar a página
4. ✅ Sucesso: Professor ainda está na lista após reload

#### 5.2. Fluxo Completo: Criar e Visualizar Aluno

1. **Criar:** Acesse `/alunos` → Clique em "➕ Novo Aluno" → Preencha o formulário completo → Salve
2. **Listar:** Verifique se o aluno aparece na lista com todos os dados
3. **Persistência:** Recarregue a página
4. ✅ Sucesso: Aluno permanece na lista com dados corretos

#### 5.3. Navegação Entre Módulos

1. Crie um professor em `/professores`
2. Navegue para `/alunos` e crie um aluno
3. Navegue para `/usuarios` e visualize os usuários
4. Volte para `/professores`
5. ✅ Sucesso: 
   - Todas as navegações funcionam sem reload de página
   - Dados persistem entre navegações
   - Nenhum erro no console

---

### 6. Testes de API Direta (Bypass do Frontend)

Use `curl` ou Postman para testar a API diretamente:

#### 6.1. Teste de CORS com OPTIONS

```bash
# Teste de preflight CORS
curl -X OPTIONS http://distrischool.local/api/v1/professores \
  -H "Origin: http://distrischool.local" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v
```

✅ **Sucesso:** Headers CORS presentes na resposta:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: *
Access-Control-Max-Age: 3600
```

#### 6.2. GET Professores

```bash
curl http://distrischool.local/api/v1/professores
```

✅ **Sucesso:** JSON com lista de professores

#### 6.3. POST Professor

```bash
curl -X POST http://distrischool.local/api/v1/professores \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Carlos Silva",
    "email": "carlos@escola.com",
    "especialidade": "Física",
    "dataContratacao": "2025-01-20"
  }'
```

✅ **Sucesso:** JSON do professor criado com ID

#### 6.4. DELETE Professor

```bash
# Substitua {id} pelo ID de um professor
curl -X DELETE http://distrischool.local/api/v1/professores/{id}
```

✅ **Sucesso:** Status 200 ou 204

#### 6.5. GET Alunos

```bash
curl http://distrischool.local/api/alunos
```

✅ **Sucesso:** JSON com lista de alunos

#### 6.6. POST Aluno

```bash
curl -X POST http://distrischool.local/api/alunos \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Lucas Mendes",
    "matricula": "2025003",
    "email": "lucas@email.com",
    "dataNascimento": "2009-11-10",
    "endereco": {
      "rua": "Rua Nova",
      "numero": "789",
      "bairro": "Vila Nova",
      "cidade": "Belo Horizonte",
      "estado": "MG",
      "cep": "30000-000"
    }
  }'
```

✅ **Sucesso:** JSON do aluno criado

#### 6.7. GET Usuários

```bash
curl http://distrischool.local/api/users
```

✅ **Sucesso:** JSON com lista de usuários

---

### 7. Testes de Performance e Carga

#### 7.1. Teste de Múltiplas Requisições Simultâneas

```bash
# Execute 10 requisições simultâneas
for i in {1..10}; do
  curl http://distrischool.local/api/v1/professores &
done
wait
```

✅ **Sucesso:** Todas as requisições retornam 200 OK

#### 7.2. Teste de Preflight Caching

1. Abra o DevTools → Aba **Network**
2. Faça uma requisição POST para criar um professor
3. Observe que a primeira vez envia OPTIONS + POST
4. Faça outra requisição POST imediatamente
5. ✅ Sucesso: Segunda requisição pula o OPTIONS (cache por 1 hora)

---

## 🔧 Troubleshooting

### Problema 1: Erro CORS persiste

**Sintomas:**
```
Access to fetch... has been blocked by CORS policy
```

**Soluções:**
1. Limpar cache do navegador: `Ctrl+Shift+Delete`
2. Usar modo anônimo: `Ctrl+Shift+N`
3. Verificar configuração do API Gateway:
   ```bash
   kubectl logs -f deployment/api-gateway-deployment
   ```
4. Verificar se o Ingress está ativo:
   ```bash
   kubectl get ingress
   ```

### Problema 2: Frontend não carrega

**Soluções:**
1. Verificar pods:
   ```bash
   kubectl get pods | grep frontend
   ```
2. Verificar logs:
   ```bash
   kubectl logs -f deployment/frontend-deployment
   ```
3. Verificar se o Ingress Controller está rodando:
   ```bash
   kubectl get pods -n ingress-nginx
   ```

### Problema 3: API retorna 404

**Soluções:**
1. Verificar configuração de rotas no Gateway:
   ```bash
   kubectl exec deployment/api-gateway-deployment -- cat /app/config/application.yml
   ```
2. Testar rota diretamente no pod:
   ```bash
   kubectl port-forward deployment/api-gateway-deployment 8080:8080
   curl http://localhost:8080/api/v1/professores
   ```

### Problema 4: Dados não persistem

**Soluções:**
1. Verificar se o PostgreSQL está rodando:
   ```bash
   kubectl get pods | grep postgres
   kubectl logs -f deployment/postgres
   ```
2. Verificar conexão dos serviços com o banco:
   ```bash
   kubectl logs -f deployment/professor-tecadm-service | grep -i "database\|connection"
   ```

### Problema 5: Ingress não funciona

**Soluções:**
1. Verificar se o addon está habilitado:
   ```bash
   minikube addons list | grep ingress
   ```
2. Habilitar se necessário:
   ```bash
   minikube addons enable ingress
   ```
3. Esperar o Ingress Controller inicializar (pode levar 1-2 minutos):
   ```bash
   kubectl get pods -n ingress-nginx -w
   ```
4. Verificar status do Ingress:
   ```bash
   kubectl describe ingress distrischool-ingress
   ```

---

## ✅ Checklist de Validação Completa

Marque cada item conforme você valida:

### Frontend
- [ ] Dashboard carrega sem erros
- [ ] Navegação entre páginas funciona
- [ ] Nenhum erro CORS no console
- [ ] Interface responsiva em mobile

### Professores
- [ ] Lista professores (GET)
- [ ] Cria novo professor (POST)
- [ ] Exclui professor (DELETE)
- [ ] Dados persistem após reload

### Alunos
- [ ] Lista alunos (GET)
- [ ] Cria novo aluno com endereço (POST)
- [ ] Dados completos são exibidos
- [ ] Dados persistem após reload

### Usuários
- [ ] Lista usuários (GET)
- [ ] Dados são exibidos corretamente

### Integração
- [ ] Frontend → Gateway → Backend funciona
- [ ] Dados são salvos no PostgreSQL
- [ ] CORS está configurado corretamente
- [ ] Ingress roteia corretamente

### Performance
- [ ] Páginas carregam rapidamente
- [ ] Preflight caching funciona
- [ ] Múltiplas requisições funcionam

---

## 📊 Métricas de Sucesso

- ✅ **100% dos endpoints funcionando**
- ✅ **Tempo de resposta < 500ms** para listagens
- ✅ **0 erros de CORS** no console
- ✅ **Dados persistem** após reinício dos pods
- ✅ **UI responsiva** em desktop e mobile

---

## 🎯 Próximos Passos (Opcional)

Após validar todas as funcionalidades básicas, considere:

1. **Adicionar autenticação** com JWT
2. **Implementar paginação** nas listagens
3. **Adicionar filtros e busca** 
4. **Implementar atualização (PUT)** para todos os módulos
5. **Adicionar validações de formulário** mais robustas
6. **Criar testes automatizados** (E2E com Cypress)
7. **Monitoramento** com Prometheus/Grafana

---

**Versão:** 1.0  
**Data:** 2025-10-27  
**Autor:** DistriSchool Team
