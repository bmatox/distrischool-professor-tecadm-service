# DistriSchool - Plataforma de Gestão Escolar Distribuída

O **DistriSchool** é uma plataforma completa de gestão escolar baseada em arquitetura de microserviços, desenvolvida com Spring Boot, containerizada com Docker e orquestrada com Kubernetes.

## 🏗️ Arquitetura

A plataforma é composta por múltiplos microserviços independentes:

### Microserviços de Backend

1. **Professor-TecAdm Service** (porta interna 8082)
   - Gerenciamento de Professores e Técnicos Administrativos
   - CRUD completo com validações
   - Publicação de eventos no RabbitMQ

2. **Aluno Service** (porta interna 8081)
   - Gerenciamento de Alunos
   - CRUD completo com endereço
   - Integração com mensageria

3. **User Service** (porta interna 8080)
   - Gerenciamento de Usuários do sistema
   - Autenticação e autorização
   - Controle de permissões

### Infraestrutura

4. **API Gateway** (porta interna 8080, exposta via NodePort)
   - Roteamento centralizado para todos os serviços
   - Configuração de CORS
   - Ponto único de entrada para o frontend
   - **Nota:** Roda em um pod separado do User Service

5. **Frontend** (porta interna 80, exposta via NodePort ou Ingress)
   - Interface web em React/Vite com React Router
   - Dashboard de gestão completo
   - Módulos de Professores, Alunos e Usuários
   - CRUD completo para Professores e Alunos
   - Visualização de Usuários
   - Comunicação com backend via API Gateway
   - Configuração dinâmica de URL da API

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
- **React 19**
- **React Router DOM 7**
- **Vite 7**
- **Nginx** (produção)

### DevOps
- **Docker**
- **Kubernetes**
- **Kubernetes Ingress** (NGINX Ingress Controller)
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

#### ⭐ Opção 1: Deploy com Ingress (Recomendado - URLs Estáveis)

O método recomendado usa Ingress para fornecer URLs estáveis, eliminando portas dinâmicas.

**Bash (Linux/Mac):**
```bash
# Habilitar Ingress no Minikube
minikube addons enable ingress

# Deploy automatizado
./deploy-with-ingress.sh

# Adicionar ao /etc/hosts
echo "$(minikube ip) distrischool.local" | sudo tee -a /etc/hosts

# Acessar
# Frontend: http://distrischool.local
# API: http://distrischool.local/api
```

**PowerShell (Windows):**
```powershell
# Habilitar Ingress no Minikube
minikube addons enable ingress

# Deploy automatizado
.\deploy-with-ingress.ps1

# Adicionar ao arquivo hosts (executar como Administrador)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "$(minikube ip) distrischool.local"

# Acessar
# Frontend: http://distrischool.local
# API: http://distrischool.local/api
```

📖 **Guia completo:** [INGRESS_DEPLOYMENT_GUIDE.md](./INGRESS_DEPLOYMENT_GUIDE.md)

#### Opção 2: Deploy com NodePort (Portas Dinâmicas)

**Windows (PowerShell):**
```powershell
.\setup-dev-env.ps1
```

**Linux/Mac (Bash):**
```bash
./build-all.sh
./deploy-all.sh

# Obter URLs dinâmicas
minikube service frontend-service --url
minikube service api-gateway-service --url
```

📖 **Guia completo:** [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md)

#### Opção 3: Setup Manual

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

### Testes Funcionais do Frontend

Consulte [TESTING_GUIDE.md](./TESTING_GUIDE.md) para guia detalhado de testes de cada funcionalidade através do navegador.

## 🎨 Frontend - Funcionalidades

### Dashboard Principal
- Navegação entre módulos (Professores, Alunos, Usuários)
- Cards informativos sobre cada módulo
- Interface responsiva e moderna

### Módulo de Professores
- ✅ **Listar (GET):** Visualização em cards de todos os professores
- ✅ **Criar (POST):** Formulário para cadastro de novo professor
- ✅ **Excluir (DELETE):** Remoção de professor com confirmação
- 📋 Campos: Nome, Email, Especialidade, Data de Contratação

### Módulo de Alunos
- ✅ **Listar (GET):** Visualização em cards de todos os alunos
- ✅ **Criar (POST):** Formulário completo para cadastro de aluno
- 📋 Campos: Nome, Matrícula, Email, Data de Nascimento
- 📋 Endereço completo: Rua, Número, Bairro, Cidade, Estado, CEP

### Módulo de Usuários
- ✅ **Listar (GET):** Visualização em cards de todos os usuários
- 📋 Exibe: Username, Email, Função, Data de criação

### Características Técnicas
- 🔄 **SPA com React Router:** Navegação sem reload de página
- 🌐 **API Dinâmica:** Configuração via `/config.js` ou variável de ambiente
- 📱 **Design Responsivo:** Interface adaptável para desktop e mobile
- 🎨 **UI/UX Moderna:** Gradientes, animações e transições suaves
- ⚡ **Performance:** Otimizado com Vite e lazy loading

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
3. Verifique a URL configurada no frontend:
   - Com Ingress: deve usar `/api` (relativo)
   - Com NodePort: deve usar a URL completa do gateway
4. Verifique o console do navegador para erros CORS
5. Veja [INGRESS_DEPLOYMENT_GUIDE.md](./INGRESS_DEPLOYMENT_GUIDE.md) para configuração com Ingress

Para mais detalhes de troubleshooting, consulte:
- [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) - Deploy com NodePort
- [INGRESS_DEPLOYMENT_GUIDE.md](./INGRESS_DEPLOYMENT_GUIDE.md) - Deploy com Ingress
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testes funcionais

## 📚 Documentação Adicional

- **[INGRESS_DEPLOYMENT_GUIDE.md](./INGRESS_DEPLOYMENT_GUIDE.md)** - 🆕 Guia de deploy com Ingress (URLs estáveis)
- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - 🆕 Guia completo de testes funcionais por módulo
- [MESSAGING_CONTRACT.md](./MESSAGING_CONTRACT.md) - Contrato de mensageria RabbitMQ
- [TESTING_MINIKUBE.md](./TESTING_MINIKUBE.md) - Guia de deploy e testes no Minikube
- [CORS_FIX_SUMMARY.md](./CORS_FIX_SUMMARY.md) - Detalhes da correção CORS

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
