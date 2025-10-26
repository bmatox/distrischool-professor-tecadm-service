# DistriSchool - Plataforma de Gestão Escolar Distribuída

Este repositório contém a implementação completa da arquitetura de microsserviços do **DistriSchool**, incluindo:
- ✅ Backend Service (CRUD de Professores e Técnicos)
- ✅ API Gateway (Spring Cloud Gateway)
- ✅ Frontend React (Interface de Usuário)
- ✅ RabbitMQ Integration (Eventos Assíncronos)
- ✅ PostgreSQL (Banco de Dados)

## 🚀 Quick Start

### Pré-requisitos
- Docker 20.10+
- Docker Compose 2.0+

### Iniciar o Ambiente Completo

```bash
# 1. Clone o repositório
git clone <URL_DO_REPOSITORIO>
cd distrischool-professor-tecadm-service

# 2. Configure o .env (já criado, mas você pode personalizá-lo)
# As credenciais padrão são admin/admin

# 3. Inicie todos os serviços
docker compose up --build
```

### Acessar os Serviços

Após a inicialização (3-10 minutos na primeira vez):

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Frontend** | http://localhost:3000 | - |
| **API Gateway** | http://localhost:8888 | - |
| **Backend API** | http://localhost:8080 | - |
| **Swagger UI** | http://localhost:8080/swagger-ui.html | - |
| **RabbitMQ Management** | http://localhost:15672 | admin/admin |

### Parar o Ambiente

```bash
docker compose down

# Para remover volumes também (limpar dados):
docker compose down -v
```

## 🏗️ Arquitetura

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ :3000
┌──────▼──────┐
│  Frontend   │ (React + Vite)
│   (Nginx)   │
└──────┬──────┘
       │ :8888
┌──────▼──────┐
│ API Gateway │ (Spring Cloud Gateway)
└──────┬──────┘
       │ :8080
┌──────▼────────────────┐         ┌──────────┐
│  Backend Service      │────────→│ RabbitMQ │
│ (Spring Boot + JPA)   │ Events  │ :5672    │
└──────┬────────────────┘         └──────────┘
       │ :5432
┌──────▼──────┐
│ PostgreSQL  │
└─────────────┘
```

## 📁 Estrutura do Projeto

```
distrischool-professor-tecadm-service/
├── api-gateway/              # API Gateway (Spring Cloud Gateway)
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── frontend/                 # Frontend React (Vite)
│   ├── src/
│   │   └── components/
│   │       └── ProfessorList.jsx
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── src/                      # Backend Service (Spring Boot)
│   ├── main/java/
│   │   └── br/com/distrischool/professortecadm/
│   │       ├── config/       # RabbitMQ Config
│   │       ├── controller/   # REST Controllers
│   │       ├── event/        # Event Publishers
│   │       ├── model/        # JPA Entities
│   │       ├── repository/   # Spring Data
│   │       └── service/      # Business Logic
│   └── resources/
│       ├── db/migration/     # Flyway Migrations
│       └── application.properties
├── docker-compose.yml        # Orchestração completa
├── TESTING_INTEGRATION.md    # Guia de testes detalhado
├── ARCHITECTURE.md           # Documentação da arquitetura
├── ARCHITECTURE_DIAGRAM.md   # Diagramas visuais
└── IMPLEMENTATION_SUMMARY.md # Checklist de implementação
```

## 🎯 Funcionalidades Implementadas

### Backend Service (Port 8080)
- ✅ CRUD completo de Professores
- ✅ CRUD completo de Técnicos Administrativos
- ✅ Validação de dados
- ✅ Paginação de resultados
- ✅ Documentação Swagger
- ✅ Migrations automáticas (Flyway)
- ✅ Publicação de eventos RabbitMQ

### API Gateway (Port 8888)
- ✅ Roteamento de requisições
- ✅ CORS configurado
- ✅ Retry logic para resiliência
- ✅ Endpoint único de entrada

### Frontend (Port 3000)
- ✅ Lista de professores
- ✅ Estados de loading e erro
- ✅ Design responsivo
- ✅ Comunicação via API Gateway

### RabbitMQ Integration
- ✅ Exchange: `distrischool.professor.exchange`
- ✅ Filas: created, updated, deleted
- ✅ Eventos publicados automaticamente
- ✅ Pronto para consumidores futuros

## 🧪 Testar a Integração

### 1. Verificar Frontend
```bash
# Abra no navegador
http://localhost:3000

# Você verá 5 professores de exemplo
```

### 2. Criar um Professor via API
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

### 3. Verificar Evento no RabbitMQ
```bash
# Acesse: http://localhost:15672
# Login: admin/admin
# Vá para "Queues and Streams"
# Verifique que professor.created.queue recebeu 1 mensagem
```

### 4. Atualizar Frontend
```bash
# Recarregue http://localhost:3000
# O novo professor aparecerá na lista
```

## 📚 Documentação Completa

- **[TESTING_INTEGRATION.md](TESTING_INTEGRATION.md)** - Guia passo a passo de testes
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Visão geral da arquitetura
- **[ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md)** - Diagramas detalhados
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Checklist completo

## 🛠️ Tecnologias Utilizadas

### Backend
- **Java 17** - Linguagem de programação
- **Spring Boot 3.2.5** - Framework principal
- **Spring Data JPA** - Persistência de dados
- **Spring AMQP** - Integração RabbitMQ
- **Hibernate** - ORM
- **Flyway** - Migrations de banco
- **PostgreSQL Driver** - Conector de banco
- **Lombok** - Redução de boilerplate
- **SpringDoc OpenAPI** - Documentação Swagger

### API Gateway
- **Spring Cloud Gateway 2023.0.1** - Gateway reativo
- **Spring Boot 3.2.5** - Framework base
- **Netty** - Servidor web reativo

### Frontend
- **React 18** - Biblioteca UI
- **Vite 5** - Build tool e dev server
- **JavaScript ES6+** - Linguagem
- **Nginx** - Web server (produção)

### Infraestrutura
- **PostgreSQL 15** - Banco de dados
- **RabbitMQ 3** - Message broker
- **Docker** - Containerização
- **Docker Compose** - Orquestração

### Build & Development
- **Maven 3.9** - Build do backend e gateway
- **npm 10** - Gerenciador de pacotes frontend
- **Git** - Controle de versão

## 📊 Endpoints da API

### Professores

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/api/v1/professores` | Cria um novo professor |
| `GET` | `/api/v1/professores` | Lista todos os professores (paginado) |
| `GET` | `/api/v1/professores/{id}` | Busca um professor específico |
| `PUT` | `/api/v1/professores/{id}` | Atualiza dados de um professor |
| `DELETE` | `/api/v1/professores/{id}` | Remove um professor |

### Técnicos Administrativos

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/api/v1/tecnicos` | Cria um novo técnico |
| `GET` | `/api/v1/tecnicos` | Lista todos os técnicos (paginado) |
| `GET` | `/api/v1/tecnicos/{id}` | Busca um técnico específico |
| `PUT` | `/api/v1/tecnicos/{id}` | Atualiza dados de um técnico |
| `DELETE` | `/api/v1/tecnicos/{id}` | Remove um técnico |

**Nota:** Acesse via API Gateway usando `http://localhost:8888` para melhor prática.

## 🔄 Eventos RabbitMQ

O sistema publica eventos assíncronos sempre que há operações CRUD:

| Evento | Fila | Quando é Disparado |
|--------|------|-------------------|
| `ProfessorCreatedEvent` | `professor.created.queue` | Ao criar um professor |
| `ProfessorUpdatedEvent` | `professor.updated.queue` | Ao atualizar um professor |
| `ProfessorDeletedEvent` | `professor.deleted.queue` | Ao deletar um professor |

Estes eventos podem ser consumidos por outros microsserviços.

## 🔧 Desenvolvimento Local

### Compilar Backend
```bash
./mvnw clean install
```

### Compilar API Gateway
```bash
cd api-gateway
./mvnw clean install
```

### Executar Frontend em Dev Mode
```bash
cd frontend
npm install
npm run dev
# Acesse http://localhost:5173
```

## 🐛 Troubleshooting

### Frontend não carrega dados
- Verifique se o Gateway está rodando: `docker ps | grep gateway`
- Verifique console do navegador (F12) para erros
- Confirme que o Gateway está em http://localhost:8888

### Gateway não roteia
- Verifique logs: `docker logs distrischool-api-gateway`
- Teste conexão com backend: `curl http://localhost:8888/actuator/health`

### RabbitMQ não recebe eventos
- Verifique se está rodando: `docker ps | grep rabbitmq`
- Acesse Management UI: http://localhost:15672
- Verifique logs do backend: `docker logs professor-tecadm-service`

### Erro ao iniciar containers
```bash
# Limpe tudo e tente novamente
docker compose down -v
docker compose build --no-cache
docker compose up
```

## 📦 Estrutura de Banco de Dados

### Tabela: professores
| Campo | Tipo | Restrições |
|-------|------|-----------|
| id | BIGINT | PRIMARY KEY, AUTO_INCREMENT |
| nome | VARCHAR(255) | NOT NULL |
| email | VARCHAR(255) | NOT NULL, UNIQUE |
| especialidade | VARCHAR(255) | - |
| data_contratacao | DATE | NOT NULL |

### Tabela: tecnicos_administrativos  
| Campo | Tipo | Restrições |
|-------|------|-----------|
| id | BIGINT | PRIMARY KEY, AUTO_INCREMENT |
| nome | VARCHAR(255) | NOT NULL |
| email | VARCHAR(255) | NOT NULL, UNIQUE |
| setor | VARCHAR(255) | - |
| data_contratacao | DATE | NOT NULL |

## 🚀 Próximos Passos

- [ ] Implementar autenticação JWT
- [ ] Adicionar Circuit Breaker no Gateway
- [ ] Implementar rate limiting
- [ ] Criar consumidores de eventos RabbitMQ
- [ ] Adicionar testes de integração automatizados
- [ ] Implementar monitoramento (Prometheus/Grafana)
- [ ] Adicionar logging distribuído (ELK Stack)
- [ ] Deploy em Kubernetes

## 📄 Licença

Este projeto faz parte do DistriSchool e é usado para fins educacionais.

## 👥 Autores

- Bruno Matos
- Equipe DistriSchool

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📞 Suporte

Para problemas ou dúvidas:
- Consulte a [documentação completa](TESTING_INTEGRATION.md)
- Verifique os logs dos serviços
- Abra uma issue no GitHub

---

**DistriSchool - Plataforma de Gestão Escolar Distribuída v1.0** 🎓