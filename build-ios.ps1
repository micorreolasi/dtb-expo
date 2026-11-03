# Script de ayuda para compilar VisualDtb a iOS (.ipa) usando xtool y Podman
param (
    [ValidateSet("auth", "ipa", "ipa-nodata", "ipa-both", "dev", "status")]
    [string]$Action = "ipa"
)

$WorkspaceDir = (Get-Item $PSScriptRoot).FullName
$XToolDir = "$env:USERPROFILE\.xtool"

if (!(Test-Path $XToolDir)) {
    New-Item -ItemType Directory -Force -Path $XToolDir | Out-Null
}

function Invoke-BuildFullIpa {
    Write-Host "`n=== Compilando y generando el archivo .IPA CON DATOS (Biblia + Canciones) ===" -ForegroundColor Cyan
    podman run --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool dev build --ipa --configuration release
    if (Test-Path "$WorkspaceDir\xtool\VisualDTB.ipa") {
        Copy-Item "$WorkspaceDir\xtool\VisualDTB.ipa" -Destination "$WorkspaceDir\VisualDTB.ipa" -Force
        Copy-Item "$WorkspaceDir\xtool\VisualDTB.ipa" -Destination "$WorkspaceDir\VisualDTB-ConDatos.ipa" -Force
        Write-Host "`n✅ Archivo .IPA con datos listo en: $WorkspaceDir\VisualDTB-ConDatos.ipa (y VisualDTB.ipa)" -ForegroundColor Green
    }
}

function Invoke-BuildNoDataIpa {
    Write-Host "`n=== Compilando y generando el archivo .IPA SIN DATOS ===" -ForegroundColor Cyan
    $resDir = "$WorkspaceDir\VisualDTB\Resources"
    $tmpDir = "$WorkspaceDir\.xtool-nodata-tmp"
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
    try {
        foreach ($f in @("bible.json", "songs.json")) {
            $src = Join-Path $resDir $f
            if (Test-Path $src) {
                Move-Item $src -Destination (Join-Path $tmpDir $f) -Force
            }
        }
        # Limpiar recursos compilados en caché del bundle para que no queden incluidos
        Get-ChildItem "$WorkspaceDir\.build" -Recurse -Filter "bible.json" -ErrorAction SilentlyContinue | Remove-Item -Force
        Get-ChildItem "$WorkspaceDir\.build" -Recurse -Filter "songs.json" -ErrorAction SilentlyContinue | Remove-Item -Force

        podman run --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool dev build --ipa --configuration release
        if (Test-Path "$WorkspaceDir\xtool\VisualDTB.ipa") {
            Copy-Item "$WorkspaceDir\xtool\VisualDTB.ipa" -Destination "$WorkspaceDir\VisualDTB-SinDatos.ipa" -Force
            Write-Host "`n✅ Archivo .IPA sin datos listo en: $WorkspaceDir\VisualDTB-SinDatos.ipa" -ForegroundColor Green
        }
    } finally {
        foreach ($f in @("bible.json", "songs.json")) {
            $bak = Join-Path $tmpDir $f
            if (Test-Path $bak) {
                Move-Item $bak -Destination (Join-Path $resDir $f) -Force
            }
        }
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

switch ($Action) {
    "auth" {
        Write-Host "`n=== Autenticación con tu Apple ID (cuenta gratuita) ===" -ForegroundColor Cyan
        Write-Host "Introduce tu correo de Apple y tu contraseña cuando te lo pida.`n" -ForegroundColor Yellow
        podman run -it --rm -v "${XToolDir}:/root" -v "${WorkspaceDir}:/workspace" xtool-env xtool auth login --mode password
    }
    "ipa" {
        Invoke-BuildFullIpa
    }
    "ipa-nodata" {
        Invoke-BuildNoDataIpa
    }
    "ipa-both" {
        Invoke-BuildNoDataIpa
        Invoke-BuildFullIpa
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
