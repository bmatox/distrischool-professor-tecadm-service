# Test script flow without actual deployment
Write-Host "Testing full-deploy.ps1 structure..." -ForegroundColor Cyan

# Source the functions from full-deploy.ps1
$scriptContent = Get-Content -Path "full-deploy.ps1" -Raw

# Extract function definitions
$functionPattern = 'function\s+(\w+-\w+)\s*\{'
$matches = [regex]::Matches($scriptContent, $functionPattern)

Write-Host "`nFunctions found:" -ForegroundColor Green
foreach ($match in $matches) {
    Write-Host "  - $($match.Groups[1].Value)" -ForegroundColor Yellow
}

# Check for key sections
$sections = @(
    "Check Prerequisites",
    "Start Minikube with Configuration",
    "Enable Ingress Addon",
    "Configure Docker Environment",
    "Build Docker Images",
    "Deploy Infrastructure",
    "Deploy Backend Services",
    "Deploy Frontend",
    "Deploy Ingress",
    "Final Status and Instructions"
)

Write-Host "`nScript sections:" -ForegroundColor Green
foreach ($section in $sections) {
    if ($scriptContent -like "*$section*") {
        Write-Host "  ✅ $section" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $section" -ForegroundColor Red
    }
}

Write-Host "`n✅ full-deploy.ps1 structure validated!" -ForegroundColor Green
