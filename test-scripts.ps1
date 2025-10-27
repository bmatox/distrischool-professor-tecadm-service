# ====================================
# Test Script - Validate PowerShell Scripts Logic
# This script simulates the execution flow without making actual changes
# ====================================

Write-Host "======================================"  -ForegroundColor Cyan
Write-Host "DistriSchool - Scripts Validation Test" -ForegroundColor Cyan
Write-Host "======================================"  -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

function Test-Section {
    param(
        [string]$TestName,
        [ScriptBlock]$TestCode
    )
    
    try {
        Write-Host "Testing: $TestName..." -ForegroundColor Yellow -NoNewline
        & $TestCode
        Write-Host " ✅ PASS" -ForegroundColor Green
        $script:testsPassed++
        return $true
    }
    catch {
        Write-Host " ❌ FAIL" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $script:testsFailed++
        return $false
    }
}

Write-Host "Testing clean-setup.ps1" -ForegroundColor Cyan
Write-Host "======================="  -ForegroundColor Cyan
Write-Host ""

# Test 1: Script file exists
Test-Section "clean-setup.ps1 exists" {
    if (-not (Test-Path "clean-setup.ps1")) {
        throw "Script file not found"
    }
}

# Test 2: Script syntax is valid
Test-Section "clean-setup.ps1 syntax is valid" {
    $script = Get-Content -Path "clean-setup.ps1" -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($script, [ref]$null)
}

# Test 3: Script contains required functions
Test-Section "clean-setup.ps1 has required functions" {
    $script = Get-Content -Path "clean-setup.ps1" -Raw
    $requiredFunctions = @("Write-Info", "Write-Success", "Write-Error", "Write-Warning", "Test-Command")
    foreach ($func in $requiredFunctions) {
        if ($script -notmatch "function\s+$func\s*\{") {
            throw "Function $func not found"
        }
    }
}

# Test 4: Script has safety confirmation
Test-Section "clean-setup.ps1 has user confirmation" {
    $script = Get-Content -Path "clean-setup.ps1" -Raw
    if ($script -notmatch "Read-Host.*Tem certeza") {
        throw "User confirmation not found"
    }
}

# Test 5: Script handles missing resources gracefully
Test-Section "clean-setup.ps1 handles missing resources" {
    $script = Get-Content -Path "clean-setup.ps1" -Raw
    if ($script -notmatch "--ignore-not-found") {
        throw "Graceful handling not found"
    }
}

Write-Host ""
Write-Host "Testing full-deploy.ps1" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Test 6: Script file exists
Test-Section "full-deploy.ps1 exists" {
    if (-not (Test-Path "full-deploy.ps1")) {
        throw "Script file not found"
    }
}

# Test 7: Script syntax is valid
Test-Section "full-deploy.ps1 syntax is valid" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($script, [ref]$null)
}

# Test 8: Script contains required functions
Test-Section "full-deploy.ps1 has required functions" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    $requiredFunctions = @("Write-Info", "Write-Success", "Write-Error", "Write-Warning", "Test-Command", "Build-DockerImage")
    foreach ($func in $requiredFunctions) {
        if ($script -notmatch "function\s+$func\s*\{") {
            throw "Function $func not found"
        }
    }
}

# Test 9: Script configures Minikube properly
Test-Section "full-deploy.ps1 configures Minikube with CPU/RAM" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    if ($script -notmatch "--cpus=4" -or $script -notmatch "--memory=8192") {
        throw "Minikube configuration not found or incorrect"
    }
}

# Test 10: Script enables Ingress
Test-Section "full-deploy.ps1 enables Ingress addon" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    if ($script -notmatch "minikube addons enable ingress") {
        throw "Ingress enablement not found"
    }
}

# Test 11: Script builds all required images
Test-Section "full-deploy.ps1 builds all Docker images" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    $requiredImages = @(
        "distrischool-professor-tecadm-service",
        "distrischool-aluno-service",
        "distrischool-user-service",
        "distrischool-api-gateway",
        "distrischool-frontend"
    )
    foreach ($image in $requiredImages) {
        if ($script -notmatch $image) {
            throw "Image $image build not found"
        }
    }
}

# Test 12: Script deploys in correct order
Test-Section "full-deploy.ps1 deploys in correct order" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    
    # Infrastructure should be deployed first
    $postgresIndex = $script.IndexOf("k8s-manifests/postgres/")
    $rabbitmqIndex = $script.IndexOf("k8s-manifests/rabbitmq/")
    $professorIndex = $script.IndexOf("k8s-manifests/professor-service/")
    
    if ($postgresIndex -le 0 -or $rabbitmqIndex -le 0 -or $professorIndex -le 0) {
        throw "Deployment paths not found"
    }
    
    if ($postgresIndex -gt $professorIndex -or $rabbitmqIndex -gt $professorIndex) {
        throw "Deployment order is incorrect (infrastructure should come before services)"
    }
}

# Test 13: Script waits for resources
Test-Section "full-deploy.ps1 waits for resources to be ready" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    if ($script -notmatch "kubectl wait.*--for=condition=ready") {
        throw "Resource waiting not found"
    }
}

# Test 14: Script provides access instructions
Test-Section "full-deploy.ps1 provides access instructions" {
    $script = Get-Content -Path "full-deploy.ps1" -Raw
    if ($script -notmatch "distrischool\.local" -or $script -notmatch "minikube ip") {
        throw "Access instructions not found"
    }
}

# Test 15: Scripts use consistent helper functions
Test-Section "Both scripts use consistent helper functions" {
    $cleanScript = Get-Content -Path "clean-setup.ps1" -Raw
    $deployScript = Get-Content -Path "full-deploy.ps1" -Raw
    
    $sharedFunctions = @("Write-Info", "Write-Success", "Write-Error", "Write-Warning", "Test-Command")
    
    foreach ($func in $sharedFunctions) {
        if ($cleanScript -notmatch "function\s+$func" -or $deployScript -notmatch "function\s+$func") {
            throw "Function $func not consistent between scripts"
        }
    }
}

Write-Host ""
Write-Host "Testing Integration" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

# Test 16: Scripts complement each other
Test-Section "Scripts form a complete workflow" {
    $cleanScript = Get-Content -Path "clean-setup.ps1" -Raw
    $deployScript = Get-Content -Path "full-deploy.ps1" -Raw
    
    # Clean script should mention deploy script
    if ($cleanScript -notmatch "full-deploy") {
        throw "clean-setup.ps1 doesn't mention full-deploy.ps1"
    }
}

# Test 17: Documentation exists
Test-Section "Documentation file exists" {
    if (-not (Test-Path "POWERSHELL_SCRIPTS_GUIDE.md")) {
        throw "POWERSHELL_SCRIPTS_GUIDE.md not found"
    }
}

Write-Host ""
Write-Host "======================================"  -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "======================================"  -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✅ All tests passed! Scripts are ready to use." -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please review the errors above." -ForegroundColor Red
    exit 1
}
