<# 
USO:
.\scripts\guardar_github.ps1

Con mensaje personalizado:
.\scripts\guardar_github.ps1 "Actualizar calculadora"

Sirve para guardar los cambios y subirlos al repositorio de GitHub.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [string]$Mensaje = "Actualizar calculadora"
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "Guardando cambios en Git..." -ForegroundColor Cyan
git add .
git commit -m $Mensaje
git push

Write-Host "Cambios subidos a GitHub." -ForegroundColor Green
