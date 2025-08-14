# Script de inicio para configurar el servidor de Minecraft en Windows
# Debe ser ejecutado con permisos de Administrador en PowerShell

# --- CONFIGURACIÓN ---
$repoUrl = "TU_URL_DEL_REPOSITORIO"
$installDir = "C:\minecraft-server"
$compressedData = "data.zip"
# ---------------------

# --- FUNCIONES ---
function Check-And-Install-Git {
    if (-not (Get-Command "git.exe" -ErrorAction SilentlyContinue)) {
        Write-Host "--- Git no encontrado. Instalando..."
        winget install Git.Git
        Write-Host "--- Git instalado."
    } else {
        Write-Host "--- Git ya esta instalado."
    }
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

function Clone-Repo {
    if (Test-Path -Path $installDir) {
        Write-Host "--- El directorio de instalacion ya existe. Saliendo."
        exit
    }
    Write-Host "--- Clonando el repositorio de GitHub..."
    git clone $repoUrl $installDir
    Write-Host "--- Repositorio clonado con exito en $installDir."
}

function Decompress-Data {
    if (-not (Test-Path -Path $compressedData)) {
        Write-Host "--- Archivo de datos comprimido '$compressedData' no encontrado. Saliendo."
        exit
    }
    Write-Host "--- Descomprimiendo la carpeta de datos..."
    Expand-Archive -Path $compressedData -DestinationPath (Join-Path -Path $installDir -ChildPath $null) -Force
    Write-Host "--- Carpeta 'data' descomprimida con exito."
}

function Start-And-Schedule {
    Write-Host "--- Configurando y levantando el servidor..."
    Set-Location -Path $installDir
    .\scripts\win\levantar.ps1
    .\scripts\win\schedule_backup.ps1
    Write-Host "--- Servidor iniciado y tareas de backup programadas."
}

# --- EJECUCIÓN ---
Write-Host "--- Iniciando el script de instalacion del servidor de Minecraft..."
Check-And-Install-Git
Check-And-Install-Docker
Clone-Repo
Decompress-Data
Start-And-Schedule
Write-Host "--- Configuracion completa! El servidor esta funcionando."