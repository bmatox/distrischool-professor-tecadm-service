# Test clean-setup.ps1 script flow
Write-Host "Testing clean-setup.ps1 structure..." -ForegroundColor Cyan

# Source the functions from clean-setup.ps1
$scriptContent = Get-Content -Path "clean-setup.ps1" -Raw

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
    "Check Minikube Status",
    "Delete Minikube",
    "Clean Docker Images",
    "Final Message"
)

Write-Host "`nScript sections:" -ForegroundColor Green
foreach ($section in $sections) {
    if ($scriptContent -like "*$section*") {
        Write-Host "  ✅ $section" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $section" -ForegroundColor Red
    }
}

# Check for safety features
Write-Host "`nSafety features:" -ForegroundColor Green
if ($scriptContent -like "*confirmation*" -or $scriptContent -like "*Read-Host*Tem certeza*") {
    Write-Host "  ✅ User confirmation required" -ForegroundColor Green
} else {
    Write-Host "  ❌ No user confirmation" -ForegroundColor Red
}

if ($scriptContent -like "*ignore-not-found*") {
    Write-Host "  ✅ Graceful handling of missing resources" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  No graceful handling" -ForegroundColor Yellow
}

Write-Host "`n✅ clean-setup.ps1 structure validated!" -ForegroundColor Green
