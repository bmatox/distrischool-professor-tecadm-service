# DistriSchool - Plataforma de Gestão Escolar Distribuída

O **DistriSchool** é uma plataforma completa de gestão escolar baseada em arquitetura de microserviços, desenvolvida com Spring Boot, containerizada com Docker e orquestrada com Kubernetes.

## 🏗️ Arquitetura

A plataforma é composta por múltiplos microserviços independentes:

### Microserviços de Backend

1. **Professor-TecAdm Service** (porta 8082)
   - Gerenciamento de Professores e Técnicos Administrativos
   - CRUD completo com validações
   - Publicação de eventos no RabbitMQ

2. **Aluno Service** (porta 8081)
   - Gerenciamento de Alunos
   - CRUD completo com endereço
   - Integração com mensageria

3. **User Service** (porta 8080)
   - Gerenciamento de Usuários do sistema
   - Autenticação e autorização
   - Controle de permissões

### Infraestrutura

4. **API Gateway** (porta 8080)
   - Roteamento centralizado para todos os serviços
   - Configuração de CORS
   - Ponto único de entrada para o frontend

5. **Frontend** (porta 80)
   - Interface web em React/Vite
   - Visualização de professores
   - Comunicação com backend via API Gateway

6. **PostgreSQL**
   - Banco de dados relacional
   - Migrations gerenciadas com Flyway

7. **RabbitMQ**
   - Mensageria assíncrona entre serviços
   - Exchange padronizado: `distrischool.events.exchange`
   - Console de gerenciamento na porta 15672

## 🚀 Tecnologias

### Backend
- **Java 17**
- **Spring Boot 3.5.6**
- **Spring Cloud Gateway 2024.0.2**
- **Spring Data JPA**
- **Spring AMQP** (RabbitMQ)
- **Spring Security**
- **Flyway** (migrations)
- **Lombok**
- **SpringDoc OpenAPI** (Swagger)

### Frontend
- **React 18**
- **Vite**
- **Nginx** (produção)

### DevOps
- **Docker**
- **Kubernetes**
- **Minikube** (desenvolvimento local)
- **Maven**

## 📋 Pré-requisitos

- **Docker** instalado e rodando
- **Minikube** instalado (versão 1.30+)
- **kubectl** instalado
- **Java 17** (para builds locais)
- **Node.js 18+** (para desenvolvimento do frontend)
- **Git**
- Pelo menos **8GB de RAM** disponível

## 🎯 Início Rápido

### 1. Clone o Repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd distrischool-professor-tecadm-service
```

### 2. Deploy no Minikube

Siga o guia completo em [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) para instruções detalhadas de deploy.

**Resumo rápido:**

```bash
# Inicie o Minikube
minikube start --cpus=4 --memory=8192

# Configure o Docker para usar o daemon do Minikube
eval $(minikube docker-env)

# Construa todas as imagens
docker build -t distrischool-professor-tecadm-service:latest .
cd Distrischool-aluno-main && docker build -t distrischool-aluno-service:latest . && cd ..
cd distrischool-user-service-main/user-service && docker build -t distrischool-user-service:latest . && cd ../..
cd api-gateway && docker build -t distrischool-api-gateway:latest . && cd ..
cd frontend && docker build -t distrischool-frontend:latest . && cd ..

# Faça o deploy
kubectl apply -f k8s-manifests/postgres/
kubectl apply -f k8s-manifests/rabbitmq/
kubectl apply -f k8s-manifests/professor-service/
kubectl apply -f k8s-manifests/aluno-service/
kubectl apply -f k8s-manifests/user-service/
kubectl apply -f k8s-manifests/api-gateway/
kubectl apply -f k8s-manifests/frontend/

# Acesse os serviços
minikube service frontend-service
minikube service api-gateway-service --url
minikube service rabbitmq-service --url
```

## 📁 Estrutura do Projeto

```
.
├── src/                                    # Código do Professor Service
├── Distrischool-aluno-main/               # Código do Aluno Service
├── distrischool-user-service-main/        # User Service e API Gateway
│   ├── api-gateway/                       # API Gateway
│   └── user-service/                      # User Service
├── api-gateway/                           # API Gateway (cópia na raiz)
├── frontend/                              # Frontend React
├── k8s-manifests/                         # Manifestos Kubernetes
│   ├── postgres/                          # PostgreSQL
│   ├── rabbitmq/                          # RabbitMQ
│   ├── professor-service/                 # Professor Service
│   ├── aluno-service/                     # Aluno Service
│   ├── user-service/                      # User Service
│   ├── api-gateway/                       # API Gateway
│   └── frontend/                          # Frontend
├── MESSAGING_CONTRACT.md                  # Contrato de mensageria
├── TESTING_MINIKUBE.md                    # Guia de deploy no Minikube
├── docker-compose.yml                     # Docker Compose (dev local)
└── README.md                              # Este arquivo
```

## 🔌 Endpoints da API

### Via API Gateway (http://localhost:8080 ou minikube service)

#### Professores
- `GET /api/v1/professores` - Lista professores (paginado)
- `GET /api/v1/professores/{id}` - Busca professor por ID
- `POST /api/v1/professores` - Cria novo professor
- `PUT /api/v1/professores/{id}` - Atualiza professor
- `DELETE /api/v1/professores/{id}` - Remove professor

#### Alunos
- `GET /api/alunos` - Lista alunos
- `GET /api/alunos/{id}` - Busca aluno por ID
- `GET /api/alunos/matricula/{matricula}` - Busca por matrícula
- `POST /api/alunos` - Cria novo aluno
- `PUT /api/alunos/{id}` - Atualiza aluno
- `DELETE /api/alunos/{id}` - Remove aluno

#### Usuários
- `GET /api/users` - Lista usuários (paginado)
- `GET /api/users/{id}` - Busca usuário por ID
- `POST /api/users` - Cria novo usuário
- `PUT /api/users/{id}` - Atualiza usuário
- `DELETE /api/users/{id}` - Remove usuário

## 📨 Mensageria (RabbitMQ)

Todos os serviços publicam eventos em uma exchange padronizada. Veja [MESSAGING_CONTRACT.md](./MESSAGING_CONTRACT.md) para detalhes completos.

### Exchange
- **Nome:** `distrischool.events.exchange`
- **Tipo:** topic
- **Durável:** true

### Routing Keys
- `professor.created` - Professor criado
- `professor.updated` - Professor atualizado
- `professor.deleted` - Professor removido
- `aluno.created` - Aluno criado
- `aluno.updated` - Aluno atualizado
- `aluno.deleted` - Aluno removido
- `user.created` - Usuário criado
- `user.updated` - Usuário atualizado
- `user.deleted` - Usuário removido

## 🧪 Testes

### Build e Testes Unitários

```bash
# Professor Service
./mvnw clean test

# Aluno Service
cd Distrischool-aluno-main
./mvnw clean test

# User Service
cd distrischool-user-service-main/user-service
./mvnw clean test
```

### Testes de Integração no Minikube

Consulte [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) para cenários de teste completos.

## 🔧 Desenvolvimento Local

### Backend (sem Kubernetes)

Cada serviço pode ser executado localmente com PostgreSQL e RabbitMQ:

```bash
# Inicie PostgreSQL e RabbitMQ
docker-compose up -d postgres rabbitmq

# Execute o serviço
./mvnw spring-boot:run

# Ou
./mvnw clean package
java -jar target/*.jar
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

Acesse: http://localhost:5173

## 📊 Monitoramento

### Health Checks

Todos os serviços expõem endpoints de health:
- Professor Service: http://professor-tecadm-service:8082/actuator/health
- Aluno Service: http://aluno-service:8081/actuator/health
- User Service: http://user-service:8080/actuator/health
- API Gateway: http://api-gateway-service:8080/actuator/health

### RabbitMQ Management Console

Acesse a console de gerenciamento do RabbitMQ:
- URL: `minikube service rabbitmq-service --url` (porta 15672)
- Usuário: `guest`
- Senha: `guest`

### Kubernetes Dashboard

```bash
minikube dashboard
```

## 🐛 Troubleshooting

### Serviço não inicia

```bash
# Verifique os logs
kubectl logs <pod-name>

# Verifique o status
kubectl describe pod <pod-name>
```

### Erro de conexão com o banco

Verifique se o PostgreSQL está rodando:
```bash
kubectl get pods | grep postgres
kubectl logs <postgres-pod-name>
```

### Frontend não carrega dados

1. Verifique se o API Gateway está acessível
2. Verifique a configuração de CORS no Gateway
3. Verifique a URL configurada no frontend (VITE_API_URL)

Para mais detalhes de troubleshooting, consulte [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md).

## 📚 Documentação Adicional

- [MESSAGING_CONTRACT.md](./MESSAGING_CONTRACT.md) - Contrato de mensageria RabbitMQ
- [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) - Guia completo de deploy e testes no Minikube

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 👥 Autores

- DistriSchool Team

## 🙏 Agradecimentos

- Spring Boot Team
- RabbitMQ Team
- Kubernetes Community
