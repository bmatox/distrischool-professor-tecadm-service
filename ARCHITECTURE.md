# DistriSchool - Arquitetura Completa

Este repositório contém a implementação completa da arquitetura de microsserviços do DistriSchool, incluindo:

## Estrutura do Projeto

```
distrischool-professor-tecadm-service/
├── api-gateway/                 # API Gateway (Spring Cloud Gateway)
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── frontend/                    # Frontend React (Vite)
│   ├── src/
│   │   └── components/
│   │       └── ProfessorList.jsx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── src/                         # Backend Service (Spring Boot)
│   ├── main/
│   │   ├── java/
│   │   │   └── br/com/distrischool/professortecadm/
│   │   │       ├── config/      # RabbitMQ Configuration
│   │   │       ├── controller/  # REST Controllers
│   │   │       ├── dto/         # Data Transfer Objects
│   │   │       ├── event/       # Event Publishers & DTOs
│   │   │       ├── model/       # JPA Entities
│   │   │       ├── repository/  # Spring Data Repositories
│   │   │       └── service/     # Business Logic
│   │   └── resources/
│   │       ├── db/migration/    # Flyway SQL Migrations
│   │       └── application.properties
├── docker-compose.yml           # Orchestration de todos os serviços
├── Dockerfile                   # Backend Dockerfile
├── TESTING_INTEGRATION.md       # Guia de testes
└── README.md                    # Este arquivo
```

## Componentes

### 1. Backend Service (Professor-TecAdm-Service)
- **Porta**: 8080
- **Tecnologia**: Spring Boot 3.2.5, Java 17
- **Responsabilidade**: CRUD de Professores e Técnicos Administrativos
- **Funcionalidades**:
  - API REST completa
  - Integração com PostgreSQL via JPA/Hibernate
  - Migrations automáticas com Flyway
  - Publicação de eventos assíncronos para RabbitMQ

### 2. API Gateway
- **Porta**: 8888
- **Tecnologia**: Spring Cloud Gateway
- **Responsabilidade**: Ponto de entrada único para todos os microsserviços
- **Funcionalidades**:
  - Roteamento de requisições
  - CORS configurado
  - Retry logic para resiliência

### 3. Frontend
- **Porta**: 3000
- **Tecnologia**: React 18 + Vite
- **Responsabilidade**: Interface de usuário
- **Funcionalidades**:
  - Lista de professores
  - Comunicação com backend através do Gateway
  - Design responsivo

### 4. Infraestrutura

#### PostgreSQL
- **Porta**: 5432
- **Versão**: 15
- **Credenciais**: admin/admin (configurável via .env)

#### RabbitMQ
- **Porta AMQP**: 5672
- **Porta Management**: 15672
- **Versão**: 3-management
- **Credenciais**: admin/admin (configurável via .env)
- **Filas**:
  - `professor.created.queue`
  - `professor.updated.queue`
  - `professor.deleted.queue`

## Início Rápido

### Pré-requisitos
- Docker 20.10+
- Docker Compose 2.0+

### Executar o Ambiente Completo

1. Clone o repositório
2. Configure o arquivo `.env` (já criado, mas você pode personalizá-lo)
3. Execute:

```bash
docker compose up --build
```

4. Acesse:
   - Frontend: http://localhost:3000
   - API Gateway: http://localhost:8888
   - Backend: http://localhost:8080
   - RabbitMQ Management: http://localhost:15672

### Parar o Ambiente

```bash
docker compose down
```

## Documentação Detalhada

Para instruções completas de teste e validação, consulte [TESTING_INTEGRATION.md](TESTING_INTEGRATION.md).

## Fluxo de Dados

```
┌─────────────┐
│   Browser   │
│ (Frontend)  │
└──────┬──────┘
       │ http://localhost:3000
       ↓
┌─────────────┐
│ API Gateway │
│   :8888     │
└──────┬──────┘
       │
       ↓
┌─────────────────────┐         ┌──────────────┐
│  Backend Service    │────────→│  RabbitMQ    │
│  (Professor)  :8080 │ Events  │  :5672/15672 │
└──────┬──────────────┘         └──────────────┘
       │
       ↓
┌─────────────┐
│ PostgreSQL  │
│   :5432     │
└─────────────┘
```

## Eventos Publicados

O serviço de backend publica eventos assíncronos para RabbitMQ sempre que há operações de CRUD:

- **professor.created**: Quando um professor é criado
- **professor.updated**: Quando um professor é atualizado
- **professor.deleted**: Quando um professor é deletado

Estes eventos podem ser consumidos por outros microsserviços para manter sincronização ou realizar ações complementares.

## Endpoints Principais

### Via API Gateway (Recomendado)

- `GET http://localhost:8888/api/v1/professores` - Lista professores
- `POST http://localhost:8888/api/v1/professores` - Cria professor
- `GET http://localhost:8888/api/v1/professores/{id}` - Busca professor
- `PUT http://localhost:8888/api/v1/professores/{id}` - Atualiza professor
- `DELETE http://localhost:8888/api/v1/professores/{id}` - Remove professor

### Documentação Swagger

- Backend: http://localhost:8080/swagger-ui.html
- (Gateway não expõe Swagger, use a documentação do backend)

## Desenvolvimento

### Compilar localmente

Backend:
```bash
./mvnw clean install
```

API Gateway:
```bash
cd api-gateway && ./mvnw clean install
```

Frontend:
```bash
cd frontend && npm install && npm run build
```

## Tecnologias Utilizadas

- **Backend**: Spring Boot 3.2.5, Spring Data JPA, Spring AMQP, Flyway
- **Gateway**: Spring Cloud Gateway 2023.0.1
- **Frontend**: React 18, Vite, Fetch API
- **Database**: PostgreSQL 15
- **Message Broker**: RabbitMQ 3
- **Build**: Maven 3.9, npm 10
- **Runtime**: Java 17, Node.js 20
- **Container**: Docker, Docker Compose
- **Web Server (Frontend)**: Nginx

## Próximos Passos

- [ ] Adicionar autenticação e autorização (JWT)
- [ ] Implementar Circuit Breaker no Gateway
- [ ] Adicionar rate limiting
- [ ] Criar consumidores de eventos RabbitMQ
- [ ] Implementar testes de integração automatizados
- [ ] Adicionar monitoramento e métricas (Prometheus/Grafana)
- [ ] Implementar logging distribuído (ELK Stack)
- [ ] Deploy em Kubernetes

## Licença

Este projeto é parte do DistriSchool e é usado para fins educacionais.

## Autores

- Bruno Matos
- Equipe DistriSchool
