#!/bin/bash

# Script to validate application configuration files
# This script validates that all application.properties/yml files have the correct property mappings

set -e

echo "=============================================="
echo "Application Configuration Validation Script"
echo "=============================================="
echo ""

# Detect repository root dynamically
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_PASSED=true

# Function to check if a property mapping exists in a file (handles both properties and yml)
check_property() {
    local file=$1
    local property=$2
    local env_var=$3
    
    # For .properties files
    if [[ $file == *.properties ]]; then
        if grep -q "$property.*\${$env_var" "$file"; then
            echo "✅ $property maps to \${$env_var}"
            return 0
        fi
    # For .yml files
    elif [[ $file == *.yml ]]; then
        # In YAML, the property is nested, so we just check for the env var reference
        if grep -q "\${$env_var" "$file"; then
            echo "✅ Found mapping to \${$env_var}"
            return 0
        fi
    fi
    
    echo "❌ Expected mapping to \${$env_var} not found"
    VALIDATION_PASSED=false
    return 1
}

# Function to validate an application config file
validate_config() {
    local service_name=$1
    local config_file=$2
    local schema_name=$3
    
    echo ""
    echo "Validating $service_name application configuration..."
    echo "File: $config_file"
    echo ""
    
    if [ ! -f "$config_file" ]; then
        echo "❌ Config file not found: $config_file"
        VALIDATION_PASSED=false
        return 1
    fi
    
    # Check database configuration
    echo "Database Configuration:"
    check_property "$config_file" "spring.datasource.url" "SPRING_DATASOURCE_URL"
    check_property "$config_file" "spring.datasource.username" "SPRING_DATASOURCE_USERNAME"
    check_property "$config_file" "spring.datasource.password" "SPRING_DATASOURCE_PASSWORD"
    
    echo ""
    echo "Schema Configuration:"
    check_property "$config_file" "spring.flyway.schemas" "SPRING_FLYWAY_SCHEMAS"
    check_property "$config_file" "spring.flyway.create-schemas" "SPRING_FLYWAY_CREATE_SCHEMAS"
    
    echo ""
    echo "RabbitMQ Configuration:"
    check_property "$config_file" "spring.rabbitmq.host" "SPRING_RABBITMQ_HOST"
    check_property "$config_file" "spring.rabbitmq.port" "SPRING_RABBITMQ_PORT"
    check_property "$config_file" "spring.rabbitmq.username" "SPRING_RABBITMQ_USERNAME"
    check_property "$config_file" "spring.rabbitmq.password" "SPRING_RABBITMQ_PASSWORD"
    
    echo ""
}

# Validate professor-tecadm-service
validate_config "professor-tecadm-service" \
    "$REPO_ROOT/src/main/resources/application.properties" \
    "professor_schema"

# Validate user-service
validate_config "user-service" \
    "$REPO_ROOT/distrischool-user-service-main/user-service/src/main/resources/application.yml" \
    "user_schema"

# Validate aluno-service
validate_config "aluno-service" \
    "$REPO_ROOT/distrischool-aluno-main/src/main/resources/application.properties" \
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
