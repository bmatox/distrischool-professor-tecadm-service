# Guia de Teste de Integração - DistriSchool

Este guia descreve como testar a integração completa entre Frontend, API Gateway, Backend e RabbitMQ do projeto DistriSchool.

## Arquitetura da Integração

```
[Frontend React:3000] 
       ↓
[API Gateway:8888] 
       ↓
[Backend Service:8080] → [RabbitMQ:5672/15672]
       ↓
[PostgreSQL:5432]
```

## Pré-requisitos

Antes de iniciar os testes, certifique-se de ter instalado:

- **Docker** (versão 20.10 ou superior)
- **Docker Compose** (versão 2.0 ou superior)
- Um navegador web moderno (Chrome, Firefox, Edge, etc.)
- (Opcional) Uma ferramenta para testar APIs como Postman ou Insomnia

## Passo 1: Configurar Variáveis de Ambiente

1. Verifique se o arquivo `.env` existe na raiz do projeto. Se não existir, crie-o com o seguinte conteúdo:

```env
# Variáveis de ambiente para o contêiner do PostgreSQL
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
POSTGRES_DB=professortecadm_db

# Variáveis de ambiente para o RabbitMQ
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin
```

## Passo 2: Iniciar Todo o Ambiente

Execute o seguinte comando na raiz do projeto para iniciar todos os serviços:

```bash
docker-compose up --build
```

**O que este comando faz:**
- Baixa as imagens necessárias (PostgreSQL, RabbitMQ)
- Compila o Backend (professor-tecadm-service)
- Compila o API Gateway
- Compila o Frontend React
- Inicia todos os containers na ordem correta

**Aguarde até ver mensagens indicando que todos os serviços estão rodando:**
- `professor-tecadm-service` - "Started DistrischoolProfessorTecadmServiceApplication"
- `distrischool-api-gateway` - "Started ApiGatewayApplication"
- `distrischool-frontend` - Nginx iniciado

Este processo pode levar de 3 a 10 minutos na primeira execução (devido ao download de dependências e compilação).

## Passo 3: Verificar os Serviços

Após a inicialização, verifique se todos os serviços estão acessíveis:

### 3.1. PostgreSQL
- **Porta**: 5432
- **Conexão**: Você pode conectar usando qualquer cliente PostgreSQL
- **Credenciais**: admin/admin

### 3.2. RabbitMQ Management Console
- **URL**: http://localhost:15672
- **Credenciais**: admin/admin
- **Verificação**: 
  - Acesse o painel de gerenciamento
  - Vá para a aba "Queues and Streams"
  - Você deve ver 3 filas:
    - `professor.created.queue`
    - `professor.updated.queue`
    - `professor.deleted.queue`

### 3.3. Backend Service
- **URL**: http://localhost:8080
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **Health Check**: http://localhost:8080/actuator/health

### 3.4. API Gateway
- **URL**: http://localhost:8888
- **Health Check**: http://localhost:8888/actuator/health
- **Gateway Routes**: http://localhost:8888/actuator/gateway/routes

### 3.5. Frontend
- **URL**: http://localhost:3000
- Abra no navegador e você verá a interface do DistriSchool

## Passo 4: Testar a Integração Frontend → Gateway → Backend

### 4.1. Visualizar Lista (Inicialmente Vazia)

1. Abra o navegador em http://localhost:3000
2. Você verá a página "Lista de Professores"
3. Se nenhum professor foi cadastrado, verá a mensagem: "Nenhum professor cadastrado ainda."

### 4.2. Criar um Professor via API

Use o Swagger UI ou um cliente API (Postman/cURL) para criar um professor:

**Via cURL (através do Gateway):**
```bash
curl -X POST http://localhost:8888/api/v1/professores \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Dr. João Silva",
    "email": "joao.silva@distrischool.com",
    "especialidade": "Matemática",
    "dataContratacao": "2025-01-15"
  }'
```

**Via cURL (direto no Backend):**
```bash
curl -X POST http://localhost:8080/api/v1/professores \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Dra. Maria Santos",
    "email": "maria.santos@distrischool.com",
    "especialidade": "Física",
    "dataContratacao": "2025-01-20"
  }'
```

**Resposta esperada:**
```json
{
  "id": 1,
  "nome": "Dr. João Silva",
  "email": "joao.silva@distrischool.com",
  "especialidade": "Matemática",
  "dataContratacao": "2025-01-15"
}
```

### 4.3. Verificar no Frontend

1. Volte ao navegador (http://localhost:3000)
2. Recarregue a página (F5)
3. **Você deve ver:**
   - O professor recém-criado listado
   - Nome, email, especialidade e data de contratação
   - Contador de total de professores atualizado
   - Mensagem "Dados carregados através do API Gateway"

## Passo 5: Verificar Publicação de Eventos RabbitMQ

### 5.1. Acessar RabbitMQ Management

1. Acesse http://localhost:15672
2. Faça login com admin/admin
3. Vá para a aba "Queues and Streams"

### 5.2. Verificar Mensagens nas Filas

Após criar um professor:
- A fila `professor.created.queue` deve mostrar que recebeu 1 mensagem
- Clique na fila para ver os detalhes
- Clique em "Get Message(s)" para visualizar o conteúdo

**Exemplo de mensagem:**
```json
{
  "id": 1,
  "nome": "Dr. João Silva",
  "email": "joao.silva@distrischool.com",
  "especialidade": "Matemática",
  "dataContratacao": "2025-01-15",
  "eventTimestamp": "2025-10-26T19:30:00.123456"
}
```

## Passo 6: Testar Outras Operações

### 6.1. Atualizar Professor

```bash
curl -X PUT http://localhost:8888/api/v1/professores/1 \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Dr. João Silva Júnior",
    "email": "joao.silva@distrischool.com",
    "especialidade": "Matemática Avançada",
    "dataContratacao": "2025-01-15"
  }'
```

- Verifique na fila `professor.updated.queue` que uma mensagem foi publicada
- Recarregue o frontend e veja as alterações

### 6.2. Deletar Professor

```bash
curl -X DELETE http://localhost:8888/api/v1/professores/1
```

- Verifique na fila `professor.deleted.queue` que uma mensagem foi publicada
- Recarregue o frontend e veja que o professor foi removido

## Passo 7: Verificar Logs

Para verificar que as requisições estão passando pelo Gateway:

### Ver logs do API Gateway:
```bash
docker logs -f distrischool-api-gateway
```

Você verá logs como:
```
INFO  --- [ctor-http-nio-2] o.s.cloud.gateway.handler.RoutePredicateHandlerMapping : Route matched: professor-service
INFO  --- [ctor-http-nio-2] o.s.c.g.h.RoutePredicateHandlerMapping : Mapping [Exchange: GET http://localhost:8888/api/v1/professores] to Route{id='professor-service', uri=http://app:8080, ...}
```

### Ver logs do Backend:
```bash
docker logs -f professor-tecadm-service
```

Você verá logs das requisições recebidas e eventos publicados:
```
INFO  --- [nio-8080-exec-1] b.c.d.p.service.ProfessorService : Creating professor...
INFO  --- [nio-8080-exec-1] b.c.d.p.event.ProfessorEventPublisher : Publishing professor created event: ProfessorCreatedEvent[...]
```

### Ver logs do Frontend:
```bash
docker logs -f distrischool-frontend
```

## Passo 8: Parar o Ambiente

Para parar todos os containers:

```bash
docker-compose down
```

**Para parar e remover também os volumes (limpar dados):**
```bash
docker-compose down -v
```

## Checklist de Validação

Use este checklist para confirmar que tudo está funcionando corretamente:

- [ ] Todos os containers iniciaram sem erros
- [ ] PostgreSQL está acessível na porta 5432
- [ ] RabbitMQ Management Console acessível em http://localhost:15672
- [ ] Backend acessível em http://localhost:8080
- [ ] API Gateway acessível em http://localhost:8888
- [ ] Frontend acessível em http://localhost:3000
- [ ] Frontend exibe mensagem inicial (vazia ou com dados)
- [ ] Consegui criar um professor via API
- [ ] Professor aparece na lista do frontend após recarregar
- [ ] Evento foi publicado na fila `professor.created.queue`
- [ ] Logs do Gateway mostram requisições sendo roteadas
- [ ] Consegui atualizar um professor
- [ ] Consegui deletar um professor
- [ ] Eventos de update e delete foram publicados nas respectivas filas

## Troubleshooting

### Frontend não carrega dados
- Verifique se o API Gateway está rodando: `docker ps | grep gateway`
- Verifique se há erros no console do navegador (F12)
- Confirme que a URL do Gateway está correta no código: `http://localhost:8888`

### Gateway não roteia requisições
- Verifique logs do Gateway: `docker logs distrischool-api-gateway`
- Confirme que o backend está acessível do container: `docker exec -it distrischool-api-gateway curl http://app:8080/actuator/health`

### RabbitMQ não recebe eventos
- Verifique se o RabbitMQ está rodando: `docker ps | grep rabbitmq`
- Verifique logs do backend para erros de conexão
- Confirme que as filas foram criadas no RabbitMQ Management

### Erro de compilação
- Limpe os containers e volumes: `docker-compose down -v`
- Remova imagens antigas: `docker-compose build --no-cache`
- Tente novamente: `docker-compose up --build`

## Próximos Passos

Após validar a integração básica, você pode:
1. Adicionar mais professores via API
2. Implementar um formulário de cadastro no frontend
3. Criar consumidores de eventos RabbitMQ em outros microsserviços
4. Adicionar autenticação e autorização no Gateway
5. Implementar testes automatizados de integração

## Suporte

Para problemas ou dúvidas:
- Verifique os logs de cada serviço
- Consulte a documentação do Spring Cloud Gateway
- Consulte a documentação do RabbitMQ
- Revise o código-fonte nos diretórios do projeto
