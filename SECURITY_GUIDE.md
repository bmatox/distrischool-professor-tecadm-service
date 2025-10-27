# Guia de Segurança - Proteção de Variáveis Sensíveis

## Visão Geral

Este guia fornece instruções sobre como proteger variáveis sensíveis (credenciais de banco de dados, senhas do RabbitMQ, etc.) no ambiente Kubernetes. Atualmente, os valores estão expostos diretamente nos arquivos `deployment.yaml` para facilitar o desenvolvimento e integração inicial.

## ⚠️ IMPORTANTE - Estado Atual

**Os valores de configuração estão atualmente hardcoded e expostos nos deployment files. Este é um estado temporário para fins de desenvolvimento e teste inicial.**

### Valores Atuais Expostos:
- **PostgreSQL**: `postgres/postgres`
- **RabbitMQ**: `guest/guest`
- **Database**: `distrischool_db`
- **Serviços**: `postgres-service`, `rabbitmq-service`

## 🔐 Estratégias de Proteção para Produção

### 1. Kubernetes Secrets

A maneira recomendada de proteger dados sensíveis no Kubernetes é usando **Secrets**.

#### Criar um Secret para PostgreSQL:

```bash
kubectl create secret generic postgres-credentials \
  --from-literal=username=postgres \
  --from-literal=password=SEU_PASSWORD_SEGURO_AQUI \
  --namespace=default
```

#### Criar um Secret para RabbitMQ:

```bash
kubectl create secret generic rabbitmq-credentials \
  --from-literal=username=admin \
  --from-literal=password=SEU_PASSWORD_SEGURO_AQUI \
  --namespace=default
```

#### Atualizar deployment.yaml para usar Secrets:

```yaml
env:
  - name: SPRING_DATASOURCE_USERNAME
    valueFrom:
      secretKeyRef:
        name: postgres-credentials
        key: username
  - name: SPRING_DATASOURCE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-credentials
        key: password
  - name: SPRING_RABBITMQ_USERNAME
    valueFrom:
      secretKeyRef:
        name: rabbitmq-credentials
        key: username
  - name: SPRING_RABBITMQ_PASSWORD
    valueFrom:
      secretKeyRef:
        name: rabbitmq-credentials
        key: password
```

### 2. ConfigMaps para Dados Não-Sensíveis

Use ConfigMaps para dados de configuração não-sensíveis:

```bash
kubectl create configmap database-config \
  --from-literal=url=jdbc:postgresql://postgres-service:5432/distrischool_db \
  --from-literal=host=postgres-service \
  --namespace=default
```

### 3. Sealed Secrets (Recomendado para GitOps)

Para ambientes com GitOps, use **Sealed Secrets** do Bitnami:

```bash
# Instalar Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Criar um Secret criptografado
echo -n postgres | kubectl create secret generic postgres-credentials \
  --dry-run=client \
  --from-file=password=/dev/stdin \
  -o yaml | \
  kubeseal -o yaml > sealed-postgres-secret.yaml
```

### 4. External Secrets Operator

Para integração com sistemas de gerenciamento de secrets externos (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-credentials
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: postgres-credentials
  data:
  - secretKey: username
    remoteRef:
      key: database/postgres
      property: username
  - secretKey: password
    remoteRef:
      key: database/postgres
      property: password
```

## 📋 Checklist de Migração para Produção

- [ ] **Passo 1**: Criar Kubernetes Secrets para todas as credenciais
- [ ] **Passo 2**: Atualizar todos os deployments para referenciar secrets
- [ ] **Passo 3**: Remover valores hardcoded dos arquivos YAML
- [ ] **Passo 4**: Implementar RBAC (Role-Based Access Control) para secrets
- [ ] **Passo 5**: Habilitar encryption at rest para secrets no cluster
- [ ] **Passo 6**: Implementar rotação periódica de credenciais
- [ ] **Passo 7**: Configurar auditoria de acesso a secrets
- [ ] **Passo 8**: Documentar procedimentos de recuperação de credenciais

## 🔒 Melhores Práticas de Segurança

### 1. Princípio do Menor Privilégio
- Conceda apenas as permissões mínimas necessárias para cada serviço
- Use diferentes usuários de banco de dados para cada microserviço quando possível

### 2. Rotação de Credenciais
- Implemente rotação automática de senhas a cada 90 dias
- Use ferramentas como AWS Secrets Manager ou HashiCorp Vault

### 3. Criptografia
- **Em trânsito**: Use TLS/SSL para todas as conexões de rede
- **Em repouso**: Habilite encryption at rest no Kubernetes
- **Aplicação**: Use encrypted secrets para dados sensíveis

### 4. Auditoria e Monitoramento
```bash
# Habilitar auditoria de acesso a secrets
kubectl logs -n kube-system kube-apiserver-* | grep Secret
```

### 5. Network Policies
Implemente Network Policies para restringir comunicação entre pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend
    ports:
    - protocol: TCP
      port: 5432
```

## 🚀 Exemplo de Deployment Seguro Completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: professor-tecadm-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: professor-tecadm
  template:
    metadata:
      labels:
        app: professor-tecadm
        role: backend
    spec:
      serviceAccountName: professor-service-account
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
        - name: professor-tecadm-service
          image: distrischool-professor-tecadm-service:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          ports:
            - containerPort: 8082
          env:
            - name: SPRING_DATASOURCE_URL
              valueFrom:
                configMapKeyRef:
                  name: database-config
                  key: url
            - name: SPRING_DATASOURCE_USERNAME
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: username
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: password
            - name: SPRING_FLYWAY_SCHEMAS
              value: "professor_schema"
            - name: SPRING_FLYWAY_CREATE_SCHEMAS
              value: "true"
            - name: SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA
              value: "professor_schema"
            - name: SPRING_RABBITMQ_HOST
              valueFrom:
                configMapKeyRef:
                  name: rabbitmq-config
                  key: host
            - name: SPRING_RABBITMQ_PORT
              value: "5672"
            - name: SPRING_RABBITMQ_USERNAME
              valueFrom:
                secretKeyRef:
                  name: rabbitmq-credentials
                  key: username
            - name: SPRING_RABBITMQ_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: rabbitmq-credentials
                  key: password
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8082
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8082
            initialDelaySeconds: 20
            periodSeconds: 5
```

## 📚 Recursos Adicionais

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)
- [HashiCorp Vault with Kubernetes](https://www.vaultproject.io/docs/platform/k8s)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

## 🆘 Suporte e Contato

Para questões sobre segurança ou implementação, entre em contato com a equipe de DevSecOps.

---

**AVISO**: Este documento deve ser revisado e atualizado regularmente conforme as práticas de segurança evoluem.
