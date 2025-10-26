# DistriSchool - Diagrama de Arquitetura

## Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUÁRIO FINAL                               │
│                     (Navegador Web / Browser)                        │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          │ HTTP Request
                          │ http://localhost:3000
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      CAMADA DE APRESENTAÇÃO                          │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │                    FRONTEND (React + Vite)                  │    │
│  │                      Porta: 3000 (Nginx)                    │    │
│  │                                                              │    │
│  │  Componentes:                                               │    │
│  │  • ProfessorList.jsx - Lista de professores                │    │
│  │  • App.jsx - Container principal                           │    │
│  │  • Fetch API - Comunicação HTTP                            │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          │ HTTP Request
                          │ fetch('http://localhost:8888/api/v1/professores')
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                       CAMADA DE GATEWAY                              │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │             API GATEWAY (Spring Cloud Gateway)             │    │
│  │                        Porta: 8888                          │    │
│  │                                                              │    │
│  │  Funcionalidades:                                           │    │
│  │  • Roteamento de requisições                               │    │
│  │  • CORS Configuration                                       │    │
│  │  • Retry Logic                                              │    │
│  │  • Load Balancing (futuro)                                 │    │
│  │  • Rate Limiting (futuro)                                   │    │
│  │                                                              │    │
│  │  Rotas Configuradas:                                        │    │
│  │  • /api/v1/professores/** → http://app:8080                │    │
│  │  • /api/v1/tecnicos/** → http://app:8080                   │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          │ HTTP Request (Internal Network)
                          │ http://app:8080/api/v1/professores
                          ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      CAMADA DE APLICAÇÃO                             │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │        BACKEND SERVICE (Spring Boot + Spring Data JPA)     │    │
│  │              professor-tecadm-service                       │    │
│  │                     Porta: 8080                             │    │
│  │                                                              │    │
│  │  Camadas:                                                    │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │ Controller Layer                                      │  │    │
│  │  │ • ProfessorController                                 │  │    │
│  │  │ • TecnicoAdministrativoController                    │  │    │
│  │  └────────────────┬─────────────────────────────────────┘  │    │
│  │                   │                                          │    │
│  │  ┌────────────────▼─────────────────────────────────────┐  │    │
│  │  │ Service Layer                                         │  │    │
│  │  │ • ProfessorService (+ Event Publishing)              │  │    │
│  │  │ • TecnicoAdministrativoService                       │  │    │
│  │  └────────────────┬──────────────────┬──────────────────┘  │    │
│  │                   │                  │                      │    │
│  │                   │                  │ Publish Events       │    │
│  │  ┌────────────────▼──────────────┐  │                      │    │
│  │  │ Repository Layer              │  │                      │    │
│  │  │ • ProfessorRepository         │  │                      │    │
│  │  │ • TecnicoAdministrativoRepo   │  │                      │    │
│  │  └────────────────┬──────────────┘  │                      │    │
│  │                   │                  │                      │    │
│  │  ┌────────────────▼──────────────┐  │                      │    │
│  │  │ Model/Entity Layer            │  │                      │    │
│  │  │ • Professor (JPA Entity)      │  │                      │    │
│  │  │ • TecnicoAdministrativo       │  │                      │    │
│  │  └───────────────────────────────┘  │                      │    │
│  │                                      │                      │    │
│  │  ┌─────────────────────────────────▼────────────────────┐ │    │
│  │  │ Event Layer                                           │ │    │
│  │  │ • ProfessorEventPublisher                             │ │    │
│  │  │ • ProfessorCreatedEvent                               │ │    │
│  │  │ • ProfessorUpdatedEvent                               │ │    │
│  │  │ • ProfessorDeletedEvent                               │ │    │
│  │  └───────────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────────┘    │
└────────┬────────────────────────────────────────┬────────────────────┘
         │                                         │
         │ JDBC                                    │ AMQP Protocol
         │ SQL Queries                             │ Event Messages
         ↓                                         ↓
┌─────────────────────┐                 ┌──────────────────────────┐
│   CAMADA DE DADOS   │                 │   CAMADA DE MENSAGERIA  │
│                     │                 │                          │
│  ┌──────────────┐  │                 │  ┌────────────────────┐ │
│  │  PostgreSQL  │  │                 │  │     RabbitMQ       │ │
│  │   Porta:     │  │                 │  │   Porta: 5672      │ │
│  │     5432     │  │                 │  │   Mgmt: 15672      │ │
│  │              │  │                 │  │                    │ │
│  │  Tabelas:    │  │                 │  │  Exchange:         │ │
│  │  • professores│ │                 │  │  • professor.exchange│
│  │  • tecnicos_  │  │                 │  │                    │ │
│  │    administra │  │                 │  │  Queues:           │ │
│  │    tivos      │  │                 │  │  • professor.      │ │
│  │               │  │                 │  │    created.queue   │ │
│  │  Migrations:  │  │                 │  │  • professor.      │ │
│  │  • Flyway     │  │                 │  │    updated.queue   │ │
│  │               │  │                 │  │  • professor.      │ │
│  │               │  │                 │  │    deleted.queue   │ │
│  └──────────────┘  │                 │  └────────────────────┘ │
└─────────────────────┘                 └──────────────────────────┘
```

## Fluxo de Dados Detalhado

### 1. Fluxo de Leitura (GET)

```
Browser → Frontend → API Gateway → Backend → PostgreSQL
                                                  ↓
                                             Query Data
                                                  ↓
Backend ← PostgreSQL (Results)
   ↓
API Gateway ← Backend (JSON Response)
   ↓
Frontend ← API Gateway (JSON Response)
   ↓
Browser ← Frontend (Renderiza UI)
```

### 2. Fluxo de Criação (POST)

```
Browser → Frontend → API Gateway → Backend
                                      ↓
                                   Validate
                                      ↓
                               PostgreSQL (INSERT)
                                      ↓
                               Save Success
                                      ↓
                            Publish Event → RabbitMQ
                                 ↓              ↓
                          JSON Response    Store in Queue
                                 ↓
                          API Gateway
                                 ↓
                            Frontend
                                 ↓
                            Browser
```

### 3. Fluxo de Eventos RabbitMQ

```
Backend Service
      ↓
ProfessorEventPublisher.publishProfessorCreated()
      ↓
RabbitMQ (professor.exchange)
      ↓ (routing key: professor.created)
professor.created.queue
      ↓
[Consumers Futuros]
• Email Service
• Notification Service
• Analytics Service
```

## Tecnologias por Camada

### Apresentação
- **React 18**: Biblioteca UI
- **Vite 5**: Build tool e dev server
- **Fetch API**: Cliente HTTP
- **Nginx**: Web server

### Gateway
- **Spring Cloud Gateway**: Roteamento e load balancing
- **Spring Boot 3.2.5**: Framework base
- **Netty**: Servidor web reativo

### Aplicação
- **Spring Boot 3.2.5**: Framework principal
- **Spring Web MVC**: Controllers REST
- **Spring Data JPA**: Persistência
- **Spring AMQP**: Integração RabbitMQ
- **Hibernate**: ORM
- **Flyway**: Migrations

### Dados
- **PostgreSQL 15**: Banco de dados relacional

### Mensageria
- **RabbitMQ 3**: Message broker AMQP

## Portas Utilizadas

| Serviço | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| Frontend | 3000 | HTTP | Interface web do usuário |
| API Gateway | 8888 | HTTP | Entry point único |
| Backend | 8080 | HTTP | REST API |
| PostgreSQL | 5432 | TCP | Banco de dados |
| RabbitMQ AMQP | 5672 | AMQP | Message broker |
| RabbitMQ Management | 15672 | HTTP | Console administrativo |

## Volumes Docker

| Volume | Serviço | Propósito |
|--------|---------|-----------|
| postgres-data | PostgreSQL | Persistência de dados do banco |
| rabbitmq-data | RabbitMQ | Persistência de filas e mensagens |

## Rede Docker

Todos os serviços estão na mesma rede Docker Compose padrão:
- Nome da rede: `distrischool-professor-tecadm-service_default`
- Driver: bridge
- Comunicação interna via nomes de serviço (app, db, rabbitmq, gateway, frontend)

## Dependências de Inicialização

```
1. db (PostgreSQL)
   ↓
2. rabbitmq (RabbitMQ)
   ↓
3. app (Backend Service)
   ↓
4. gateway (API Gateway)
   ↓
5. frontend (React App)
```

## Padrões de Design Utilizados

1. **Gateway Pattern**: API Gateway como ponto de entrada único
2. **Repository Pattern**: Abstração de acesso a dados
3. **Service Layer Pattern**: Lógica de negócio centralizada
4. **Event-Driven Architecture**: Comunicação assíncrona via eventos
5. **DTO Pattern**: Transferência de dados entre camadas
6. **Layered Architecture**: Separação clara de responsabilidades

## Características de Escalabilidade

### Horizontal Scaling Ready
- Frontend: Nginx pode ter múltiplas réplicas
- API Gateway: Stateless, pode ter múltiplas instâncias
- Backend: Stateless, pode ter múltiplas instâncias
- RabbitMQ: Suporta clustering
- PostgreSQL: Master-slave replication (futuro)

### Resiliência
- Gateway: Retry logic configurado
- RabbitMQ: Filas persistentes
- PostgreSQL: Dados persistidos em volume

## Observabilidade (Futuro)

```
         ┌──────────────────┐
         │   Prometheus     │
         │  (Metrics)       │
         └────────┬─────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Gateway│    │Backend│    │Rabbit│
│ /metrics   │ /metrics   │ /metrics
└───────┘    └───────┘    └───────┘
                  │
         ┌────────▼─────────┐
         │    Grafana       │
         │  (Visualization) │
         └──────────────────┘
```

---

**Diagrama de Arquitetura - DistriSchool v1.0**
*Atualizado em: 26/10/2025*
