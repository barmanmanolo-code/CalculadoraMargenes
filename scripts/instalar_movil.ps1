<# 
USO:
.\scripts\instalar_movil.ps1

Sirve para compilar la APK e instalarla en el movil conectado.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$DeviceId = "GQW8HAGQMZIV45PN"

Write-Host "Compilando APK release..." -ForegroundColor Cyan
flutter build apk --release

Write-Host "Instalando en el movil..." -ForegroundColor Cyan
flutter install -d $DeviceId

Write-Host "App movil instalada correctamente." -ForegroundColor Green
