# Script de inicio para configurar el servidor de Minecraft en Windows
# Debe ser ejecutado con permisos de Administrador en PowerShell

# --- CONFIGURACIÓN ---
# La carpeta de datos comprimida debe estar en la raíz del proyecto.
$compressedData = "data.zip"
# ---------------------

# --- FUNCIONES ---
function Get-GitHubToken {
    Write-Host ""
    $pat = Read-Host "--- Por favor, ingresa tu Personal Access Token (PAT) de GitHub"
    $env:GITHUB_TOKEN = $pat
    Write-Host "--- Token de GitHub configurado en la variable de entorno GITHUB_TOKEN para esta sesión."
    Write-Host ""
}

function Check-And-Install-Git {
    if (-not (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
        Write-Host "--- Git no encontrado. Instalando..."
        winget install Git.Git
        Write-Host "--- Git instalado."
    } else {
        Write-Host "--- Git ya esta instalado."
    }
    Get-GitHubToken # Llama a la nueva función para pedir el token
}

function Check-And-Install-Docker {
    if (-not (Get-Command "docker.exe" -ErrorAction SilentlyContinue)) {
        Write-Host "--- Docker no encontrado. Instalando..."
        winget install Docker.DockerDesktop -e
        Write-Host "--- Docker Desktop instalado. Por favor, reinicia la computadora."
        Write-Host "--- Este script continuara despues de reiniciar y configurar Docker Desktop."
        exit
    } else {
        Write-Host "--- Docker ya esta instalado."
        Write-Host "Iniciando Docker Desktop si no se esta ejecutando..."
        Start-Process "docker-desktop://"
        Start-Sleep -Seconds 10
    }
}

function Decompress-Data {
    if (-not (Test-Path -Path $compressedData)) {
        Write-Host "--- Archivo de datos comprimido '$compressedData' no encontrado. Saliendo."
        exit
    }

    # Crea la carpeta 'data' si no existe
    New-Item -Path "data" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    Write-Host "--- Descomprimiendo la carpeta de datos..."
    Expand-Archive -Path $compressedData -DestinationPath ".\data" -Force
    Write-Host "--- Carpeta 'data' descomprimida con exito."
}

function Start-And-Schedule {
    Write-Host "--- Configurando y levantando el servidor..."

    # Se asume que el script se ejecuta desde la raíz del proyecto
    .\scripts\win\levantar.ps1
    .\scripts\win\schedule_backup.ps1

    Write-Host "--- Servidor iniciado y tareas de backup programadas."
}

# --- EJECUCIÓN ---
Write-Host "--- Iniciando el script de instalacion del servidor de Minecraft..."
Check-And-Install-Git
Check-And-Install-Docker
Decompress-Data
Start-And-Schedule
Write-Host "--- Configuracion completa! El servidor esta funcionando."
