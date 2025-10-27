# Test prerequisites check from full-deploy.ps1
Write-Host "Testing prerequisites check..." -ForegroundColor Cyan

function Test-Command {
    param([string]$Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    }
    catch {
        return $false
    }
}

Write-Host "`nChecking required tools:" -ForegroundColor Green

$tools = @("minikube", "kubectl", "docker")
$allPresent = $true

foreach ($tool in $tools) {
    if (Test-Command $tool) {
        Write-Host "  ✅ $tool is available" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $tool is NOT available" -ForegroundColor Red
        $allPresent = $false
    }
}

if ($allPresent) {
    Write-Host "`n✅ All prerequisites are met!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some prerequisites are missing!" -ForegroundColor Red
    exit 1
}
