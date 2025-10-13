# Serviço de Gestão de Professores e Técnicos (distrischool-professor-tecadm-service)

Este microsserviço é um componente central do projeto **DistriSchool**, uma plataforma de gestão escolar distribuída. Sua responsabilidade é gerenciar o ciclo de vida (CRUD) das entidades de Professores e Técnicos Administrativos.

O serviço é construído seguindo uma arquitetura de microserviços, containerizado com Docker e orquestrado com Kubernetes, visando escalabilidade e tolerância a falhas.

## Tecnologias Utilizadas

* **Backend:** Java 21, Spring Boot, Spring Data JPA
* **Banco de Dados:** PostgreSQL
* **Gerenciamento de Build:** Maven
* **Migrations de Banco:** Flyway
* **DevOps:** Docker, Docker Compose, Kubernetes (Minikube para desenvolvimento)
* **Documentação da API:** SpringDoc (Swagger UI)
* **Utilitários:** Lombok

## Pré-requisitos

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas:
* JDK 17+
* Docker e Docker Compose
* Um cliente Git
* Uma IDE de sua preferência (ex: IntelliJ IDEA)
* Um cliente de API como o Postman (opcional)

## Como Executar (Ambiente de Desenvolvimento)

A maneira mais simples de executar o ambiente completo (aplicação + banco de dados) é utilizando o Docker Compose.

1.  **Clone o Repositório**
    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd distrischool-professor-tecadm-service
    ```

2.  **Configure as Variáveis de Ambiente**
    Este projeto usa um arquivo `.env` para configurar as credenciais do banco de dados localmente.
    * Crie uma cópia do arquivo `.env.example` e renomeie-a para `.env`.
    * Preencha as variáveis no arquivo `.env` com suas credenciais locais, se necessário.

3.  **Inicie os Contêineres**
    Com o Docker Desktop em execução, execute o seguinte comando na raiz do projeto:
    ```bash
    docker-compose up --build
    ```
    * `--build`: Garante que a imagem Docker da sua aplicação seja reconstruída caso haja alguma alteração no código.
    * O comando irá iniciar o contêiner do PostgreSQL e o contêiner da sua aplicação.

4.  **Para Parar Tudo**
    Quando terminar de trabalhar, pressione `Ctrl + C` no terminal onde o compose está rodando, ou execute o seguinte comando em outro terminal (na mesma pasta):
    ```bash
    docker-compose down
    ```

## Acessando os Serviços

* **Aplicação:** A API estará disponível na porta `8080`.
    * URL base: `http://localhost:8080`

* **Documentação Swagger UI:** A documentação interativa da API é gerada automaticamente e pode ser acessada em:
    * `http://localhost:8080/swagger-ui.html`

## Documentação da API

O serviço expõe endpoints REST para gerenciar Professores e Técnicos Administrativos.

### Professores (`/api/v1/professores`)

| Método | Endpoint | Descrição |
| :--- | :--- | :--- |
| `POST` | `/` | Cria um novo professor. |
| `GET` | `/` | Lista todos os professores de forma paginada. |
| `GET` | `/{id}` | Busca um professor específico pelo seu ID. |
| `PUT` | `/{id}` | Atualiza os dados de um professor existente. |
| `DELETE` | `/{id}` | Remove um professor do sistema. |

### Técnicos Administrativos (`/api/v1/tecnicos`)

*(Endpoints a serem implementados seguindo o mesmo padrão dos professores)*

| Método | Endpoint | Descrição |
| :--- | :--- | :--- |
| `POST` | `/` | Cria um novo técnico administrativo. |
| `GET` | `/` | Lista todos os técnicos administrativos de forma paginada. |
| `GET` | `/{id}` | Busca um técnico específico pelo seu ID. |
| `PUT` | `/{id}` | Atualiza os dados de um técnico existente. |
| `DELETE` | `/{id}` | Remove um técnico do sistema. |

## Estrutura de Banco de Dados

O schema do banco de dados é gerenciado automaticamente pelo **Flyway**. Os scripts de migração SQL estão localizados em:
`src/main/resources/db/migration`

Qualquer alteração na estrutura das tabelas deve ser feita criando um novo arquivo de migração (ex: `V2__Descricao_da_mudanca.sql`).