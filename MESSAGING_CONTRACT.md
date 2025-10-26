# DistriSchool - Contrato de Mensageria (RabbitMQ)

## Visão Geral

Este documento define o contrato padronizado de mensageria assíncrona entre os microsserviços do DistriSchool usando RabbitMQ.

## Configuração da Exchange

**Nome da Exchange:** `distrischool.events.exchange`
**Tipo:** `topic`
**Durável:** `true`
**Auto-delete:** `false`

## Padrão de Routing Keys

As routing keys seguem o padrão: `<entidade>.<acao>`

Exemplo: `professor.created`, `aluno.updated`, `usuario.deleted`

## Eventos e Estruturas de Mensagens

### 1. Professor Service Events

#### 1.1 Professor Created
**Routing Key:** `professor.created`

**Estrutura JSON:**
```json
{
  "id": 1,
  "nome": "João Silva",
  "email": "joao.silva@example.com",
  "especialidade": "Matemática",
  "dataContratacao": "2024-01-15",
  "type": "CREATED",
  "timestamp": "2024-10-26T22:30:00Z"
}
```

#### 1.2 Professor Updated
**Routing Key:** `professor.updated`

**Estrutura JSON:**
```json
{
  "id": 1,
  "nome": "João Silva",
  "email": "joao.silva@example.com",
  "especialidade": "Física",
  "dataContratacao": "2024-01-15",
  "type": "UPDATED",
  "timestamp": "2024-10-26T22:35:00Z"
}
```

#### 1.3 Professor Deleted
**Routing Key:** `professor.deleted`

**Estrutura JSON:**
```json
{
  "id": 1,
  "type": "DELETED",
  "timestamp": "2024-10-26T22:40:00Z"
}
```

### 2. Aluno Service Events

#### 2.1 Aluno Created
**Routing Key:** `aluno.created`

**Estrutura JSON:**
```json
{
  "id": 1,
  "nome": "Maria Santos",
  "email": "maria.santos@example.com",
  "matricula": "2024001",
  "type": "CREATED",
  "timestamp": "2024-10-26T22:30:00Z"
}
```

#### 2.2 Aluno Updated
**Routing Key:** `aluno.updated`

**Estrutura JSON:**
```json
{
  "id": 1,
  "nome": "Maria Santos",
  "email": "maria.santos@example.com",
  "matricula": "2024001",
  "type": "UPDATED",
  "timestamp": "2024-10-26T22:35:00Z"
}
```

#### 2.3 Aluno Deleted
**Routing Key:** `aluno.deleted`

**Estrutura JSON:**
```json
{
  "id": 1,
  "type": "DELETED",
  "timestamp": "2024-10-26T22:40:00Z"
}
```

### 3. User Service Events

#### 3.1 User Created
**Routing Key:** `user.created`

**Estrutura JSON:**
```json
{
  "id": 1,
  "name": "Admin User",
  "email": "admin@example.com",
  "role": "ADMIN",
  "type": "CREATED",
  "timestamp": "2024-10-26T22:30:00Z"
}
```

#### 3.2 User Updated
**Routing Key:** `user.updated`

**Estrutura JSON:**
```json
{
  "id": 1,
  "name": "Admin User",
  "email": "admin@example.com",
  "role": "ADMIN",
  "type": "UPDATED",
  "timestamp": "2024-10-26T22:35:00Z"
}
```

#### 3.3 User Deleted
**Routing Key:** `user.deleted`

**Estrutura JSON:**
```json
{
  "id": 1,
  "type": "DELETED",
  "timestamp": "2024-10-26T22:40:00Z"
}
```

## Configuração de Conexão (Kubernetes)

Todos os serviços devem usar as seguintes configurações para conectar ao RabbitMQ:

```yaml
spring:
  rabbitmq:
    host: ${RABBITMQ_HOST:rabbitmq-service}
    port: ${RABBITMQ_PORT:5672}
    username: ${RABBITMQ_USERNAME:guest}
    password: ${RABBITMQ_PASSWORD:guest}
```

## Boas Práticas

1. **Idempotência:** Todos os consumidores devem ser idempotentes para lidar com mensagens duplicadas.
2. **Dead Letter Queue:** Configure DLQ para mensagens que falharem após múltiplas tentativas.
3. **Retry Strategy:** Use estratégia exponential backoff para retentativas.
4. **Timeout:** Configure timeouts adequados para conexão (60000ms recomendado).
5. **Serialização:** Use Jackson2JsonMessageConverter para conversão JSON.
6. **Logs:** Registre todas as publicações e consumos de eventos para auditoria.

## Exemplo de Implementação

### Publisher (Publicador)

```java
@Component
@RequiredArgsConstructor
public class EventPublisher {
    private final RabbitTemplate rabbitTemplate;
    private static final String EXCHANGE = "distrischool.events.exchange";

    public void publish(String routingKey, Object payload) {
        rabbitTemplate.convertAndSend(EXCHANGE, routingKey, payload);
    }
}
```

### Consumer (Consumidor) - Opcional

```java
@Component
public class EventListener {
    
    @RabbitListener(queues = "professor.events.queue")
    public void handleProfessorEvent(String message) {
        // Processar evento
    }
}
```

## Versionamento

**Versão:** 1.0.0
**Data:** 26/10/2024
**Autor:** DistriSchool Team
