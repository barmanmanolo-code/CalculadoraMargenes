<# 
USO:
.\scripts\actualizar_web.ps1

Sirve para compilar la web de Calculadora y dejarla lista en la carpeta docs para GitHub Pages.

Recomendado antes de ejecutar este script:
.\scripts\probar_chrome.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Compilando web..." -ForegroundColor Cyan
flutter build web --base-href /CalculadoraMargenes/

Write-Host "Copiando build web a docs..." -ForegroundColor Cyan
if (Test-Path docs) {
  Remove-Item -Recurse -Force docs
}
Copy-Item -Recurse build\web docs

Write-Host "Web preparada en docs. Ejecuta guardar_github.ps1 para subirla." -ForegroundColor Green
