# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.
# Es necesario ejecutar esto en PowerShell

# --- CONFIGURACIÓN ---
$stackName = "minecraft_stack"
$githubRepo = "https://github.com/erickturriago/servidor_minecraft.git"
$githubToken = "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"
$maxBackups = 15
# ---------------------

$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\"
$backupDir = Join-Path -Path $baseDir -ChildPath "backups"
$dataDir = Join-Path -Path $baseDir -ChildPath "data"
$compressedData = Join-Path -Path $baseDir -ChildPath "data.zip"

function Detener-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Deteniendo stack: $stackName..."
    docker-compose -p $stackName down
    Write-Host "--- Stack '$stackName' detenido con exito."
}

function Levantar-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Levantando stack: $stackName..."
    docker-compose -p $stackName up -d
    Write-Host "--- Stack '$stackName' levantado con exito."
}

function Hacer-Backup-Y-Subir {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path -Path $backupDir -ChildPath "minecraft-backup-$timestamp.zip"
    
    # --- Backup local ---
    Write-Host "--- Creando backup local de los mundos y plugins en $backupFile..."
    Compress-Archive -Path (Join-Path $dataDir "world"), (Join-Path $dataDir "world_nether"), (Join-Path $dataDir "world_the_end"), (Join-Path $dataDir "plugins") -DestinationPath $backupFile -Force
    Write-Host "--- Backup local completado: $backupFile"

    # --- Preparar para Git ---
    Write-Host "--- Comprimiendo el mundo y los plugins para subir a Git..."
    if (Test-Path -Path $compressedData) {
        Remove-Item -Path $compressedData -Force
    }
    Compress-Archive -Path (Join-Path $dataDir "world"), (Join-Path $dataDir "world_nether"), (Join-Path $dataDir "world_the_end"), (Join-Path $dataDir "plugins") -DestinationPath $compressedData -Force
    Write-Host "--- Archivo 'data.zip' creado con exito."

    # --- Subir a Git ---
    Set-Location -Path $baseDir
    $githubUser = "erickturriago"
    $gitUrlWithToken = "https://$githubUser:$githubToken@github.com/erickturriago/servidor_minecraft.git"

    if (-not (Test-Path -Path ".git" -PathType Container)) {
        git init
        git remote add origin $githubRepo
    } else {
        git remote remove origin -ErrorAction SilentlyContinue | Out-Null
        git remote add origin $gitUrlWithToken
    }

    Write-Host "--- Agregando archivos al control de versiones..."
    Set-Content -Path ".gitignore" -Value "data/"

    # Limpia el cache de Git de la carpeta data/ antes de proceder
    git rm -r --cached "data" -ErrorAction SilentlyContinue | Out-Null
    
    git add .
    git commit -m "Backup automatico - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    Write-Host "--- Subiendo cambios a GitHub..."
    git push origin main

    Write-Host "--- Gestionando backups (maximo $maxBackups copias)..."
    $backups = Get-ChildItem -Path $backupDir -Filter "minecraft-backup-*.zip" | Sort-Object CreationTime -Descending
    if ($backups.Count -gt $maxBackups) {
        $backupsToDelete = $backups | Select-Object -Skip $maxBackups
        foreach ($backup in $backupsToDelete) {
            Write-Host "--- Borrando el backup mas antiguo: $($backup.Name)"
            Remove-Item -Path $backup.FullName -Force
        }
    }
    Write-Host "--- Sincronizacion con GitHub y gestion de backups completada."
}

# --- Flujo de ejecución completo ---
Detener-Stack
Hacer-Backup-Y-Subir
Levantar-Stack
