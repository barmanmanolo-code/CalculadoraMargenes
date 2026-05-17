<# 
USO:
.\scripts\probar_chrome.ps1

Sirve para abrir la app en Chrome y revisarla antes de actualizar web/movil.

Cuando termines de probar, vuelve a la terminal y pulsa:
q
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Abriendo la app en Chrome para probar..." -ForegroundColor Cyan
Write-Host "Cuando termines, pulsa q en esta terminal para cerrar Flutter run." -ForegroundColor Yellow

flutter run -d Chrome
