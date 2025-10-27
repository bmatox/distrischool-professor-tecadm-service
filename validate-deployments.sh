#!/bin/bash

# Script to validate deployment configurations
# This script validates that all deployment YAML files have the correct environment variables

set -e

echo "=============================================="
echo "Deployment Configuration Validation Script"
echo "=============================================="
echo ""

REPO_ROOT="/home/runner/work/distrischool-professor-tecadm-service/distrischool-professor-tecadm-service"
VALIDATION_PASSED=true

# Function to check if a value exists in a file
check_env_var() {
    local file=$1
    local var_name=$2
    local expected_value=$3
    
    if grep -q "name: $var_name" "$file" && grep -q "value: \"$expected_value\"" "$file"; then
        echo "✅ $var_name: $expected_value"
        return 0
    else
        echo "❌ $var_name: Expected '$expected_value' not found"
        VALIDATION_PASSED=false
        return 1
    fi
}

# Function to validate a deployment file
validate_deployment() {
    local service_name=$1
    local deployment_file=$2
    local schema_name=$3
    
    echo ""
    echo "Validating $service_name deployment..."
    echo "File: $deployment_file"
    echo ""
    
    if [ ! -f "$deployment_file" ]; then
        echo "❌ Deployment file not found: $deployment_file"
        VALIDATION_PASSED=false
        return 1
    fi
    
    # Check database configuration
    echo "Database Configuration:"
    check_env_var "$deployment_file" "SPRING_DATASOURCE_URL" "jdbc:postgresql://postgres-service:5432/distrischool_db"
    check_env_var "$deployment_file" "SPRING_DATASOURCE_USERNAME" "postgres"
    check_env_var "$deployment_file" "SPRING_DATASOURCE_PASSWORD" "postgres"
    
    echo ""
    echo "Schema Configuration:"
    check_env_var "$deployment_file" "SPRING_FLYWAY_SCHEMAS" "$schema_name"
    check_env_var "$deployment_file" "SPRING_FLYWAY_CREATE_SCHEMAS" "true"
    check_env_var "$deployment_file" "SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA" "$schema_name"
    
    echo ""
    echo "RabbitMQ Configuration:"
    check_env_var "$deployment_file" "SPRING_RABBITMQ_HOST" "rabbitmq-service"
    check_env_var "$deployment_file" "SPRING_RABBITMQ_PORT" "5672"
    check_env_var "$deployment_file" "SPRING_RABBITMQ_USERNAME" "guest"
    check_env_var "$deployment_file" "SPRING_RABBITMQ_PASSWORD" "guest"
    
    echo ""
}

# Validate professor-tecadm-service
validate_deployment "professor-tecadm-service" \
    "$REPO_ROOT/k8s-manifests/professor-service/deployment.yaml" \
    "professor_schema"

# Validate user-service
validate_deployment "user-service" \
    "$REPO_ROOT/k8s-manifests/user-service/deployment.yaml" \
    "user_schema"

# Validate aluno-service
validate_deployment "aluno-service" \
    "$REPO_ROOT/k8s-manifests/aluno-service/deployment.yaml" \
    "aluno_schema"

echo ""
echo "=============================================="
if [ "$VALIDATION_PASSED" = true ]; then
    echo "✅ All validations passed!"
    echo "=============================================="
    exit 0
else
    echo "❌ Some validations failed!"
    echo "=============================================="
    exit 1
fi
