<# 
USO:
.\scripts\actualizar_todo.ps1

Sirve para preparar la web en docs y despues instalar la app en el movil.

Recomendado antes de ejecutar este script:
.\scripts\probar_chrome.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$DeviceId = "GQW8HAGQMZIV45PN"

Write-Host "Compilando web..." -ForegroundColor Cyan
flutter build web --base-href /CalculadoraMargenes/

Write-Host "Copiando build web a docs..." -ForegroundColor Cyan
if (Test-Path docs) {
  Remove-Item -Recurse -Force docs
}
Copy-Item -Recurse build\web docs

Write-Host "Compilando APK release..." -ForegroundColor Cyan
flutter build apk --release

Write-Host "Instalando en el movil..." -ForegroundColor Cyan
flutter install -d $DeviceId

Write-Host "Web preparada en docs y movil actualizado. Ejecuta guardar_github.ps1 para subirlo." -ForegroundColor Green
