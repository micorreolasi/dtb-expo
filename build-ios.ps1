# Script de ayuda para compilar VisualDtb a iOS (.ipa) usando xtool y Podman
param (
    [ValidateSet("auth", "ipa", "dev", "status")]
    [string]$Action = "ipa"
)

$WorkspaceDir = (Get-Item $PSScriptRoot).FullName
$XToolDir = "$env:USERPROFILE\.xtool"

if (!(Test-Path $XToolDir)) {
    New-Item -ItemType Directory -Force -Path $XToolDir | Out-Null
}

switch ($Action) {
    "auth" {
        Write-Host "`n=== Autenticación con tu Apple ID (cuenta gratuita) ===" -ForegroundColor Cyan
        Write-Host "Introduce tu correo de Apple y tu contraseña cuando te lo pida.`n" -ForegroundColor Yellow
        podman run -it --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool auth login --mode password
    }
    "ipa" {
        Write-Host "`n=== Compilando y generando el archivo .IPA para sideload ===" -ForegroundColor Cyan
        podman run --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool dev build --ipa --configuration release
        if (Test-Path "$WorkspaceDir\xtool\VisualDTB.ipa") {
            Copy-Item "$WorkspaceDir\xtool\VisualDTB.ipa" -Destination "$WorkspaceDir\VisualDTB.ipa" -Force
            Write-Host "`n✅ Archivo .IPA listo en: $WorkspaceDir\VisualDTB.ipa" -ForegroundColor Green
        }
    }
    "dev" {
        Write-Host "`n=== Instalando en iPhone conectado por USB ===" -ForegroundColor Cyan
        podman run -it --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool dev run
    }
    "status" {
        Write-Host "`n=== Estado del SDK de iOS y Autenticación ===" -ForegroundColor Cyan
        Write-Host "SDK:" -ForegroundColor Yellow
        podman run --rm -v "${XToolDir}:/root" xtool-env xtool sdk status
        Write-Host "`nCuenta de Desarrollador:" -ForegroundColor Yellow
        podman run --rm -v "${XToolDir}:/root" xtool-env xtool auth status
    }
}
