# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
$stackName = "minecraft_stack"
$githubRepo = "https://github.com/erickturriago/servidor_minecraft.git"
$maxBackups = 20
# ---------------------

$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\" 
$backupDir = Join-Path -Path $baseDir -ChildPath "backups"
$dataDir = Join-Path -Path $baseDir -ChildPath "data"
$compressedData = Join-Path -Path $baseDir -ChildPath "data.zip"

# --- LECTURA DEL TOKEN ---
$tokenFilePath = Join-Path -Path $baseDir -ChildPath "token.txt"
if (Test-Path -Path $tokenFilePath) {
    $githubToken = Get-Content -Path $tokenFilePath | Select-Object -First 1
    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "--- ERROR: El archivo token.txt está vacío."
        exit
    }
} else {
    Write-Host "--- ERROR: Archivo token.txt no encontrado en la raíz del proyecto. Crea uno y añade tu token de GitHub."
    exit
}

function Detener-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Deteniendo stack: $stackName..."
    docker compose -p $stackName down
    Write-Host "--- Stack '$stackName' detenido con éxito."
}

function Levantar-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Levantando stack: $stackName..."
    docker compose -p $stackName up -d
    Write-Host "--- Stack '$stackName' levantado con éxito."
}

function Hacer-Backup-Y-Subir {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path -Path $backupDir -ChildPath "minecraft-backup-$timestamp.zip"

    # --- Archivos a respaldar ---
    $itemsToBackup = @(
        (Join-Path $dataDir "world"),
        (Join-Path $dataDir "world_nether"),
        (Join-Path $dataDir "world_the_end"),
        (Join-Path $dataDir "plugins"),
        (Join-Path $dataDir "server.properties"),
        (Join-Path $dataDir "spigot.yml"),
        (Join-Path $dataDir "bukkit.yml"),
        (Join-Path $dataDir "ops.json"),
        (Join-Path $dataDir "whitelist.json"),
        (Join-Path $dataDir "banned-ips.json"),
        (Join-Path $dataDir "banned-players.json"),
        (Join-Path $dataDir "permissions.yml")
    )

    # --- Backup local ---
    Write-Host "--- Creando backup local en $backupFile..."
    Compress-Archive -Path $itemsToBackup -DestinationPath $backupFile -Force
    Write-Host "--- Backup local completado: $backupFile"

    # --- Preparar para Git ---
    Write-Host "--- Creando data.zip para GitHub..."
    if (Test-Path -Path $compressedData) {
        Write-Host "--- Eliminando data.zip anterior..."
        Remove-Item -Path $compressedData -Force
    }
    Compress-Archive -Path $itemsToBackup -DestinationPath $compressedData -Force
    Write-Host "--- Archivo 'data.zip' creado con éxito."

    # --- Subir a Git ---
    Set-Location -Path $baseDir
    $gitUrlWithToken = "https://oauth2:$githubToken@github.com/erickturriago/servidor_minecraft.git"

    if (-not (Test-Path -Path ".git" -PathType Container)) {
        git init
        git remote add origin $githubRepo
        git branch -M main
    }

    # Asegurar .gitignore correcto
    if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" -ItemType File | Out-Null }
    if (-not (Select-String -Path ".gitignore" -Pattern "data/" -Quiet)) {
        Add-Content -Path ".gitignore" "data/"
    }
    if (-not (Select-String -Path ".gitignore" -Pattern "token.txt" -Quiet)) {
        Add-Content -Path ".gitignore" "token.txt"
    }

    # Limpia cache de data/
    git rm -r --cached "data" 2>$null | Out-Null

    # --- Pull antes de commit/push ---
    Write-Host "--- Sincronizando con GitHub (git pull)..."
    git pull $gitUrlWithToken main --allow-unrelated-histories

    Write-Host "--- Agregando archivos a Git..."
    git add .
    git commit -m "Backup automático - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 2>$null

    Write-Host "--- Subiendo cambios a GitHub..."
    git push -u $gitUrlWithToken main

    # --- Gestión de backups locales ---
    Write-Host "--- Gestionando backups (máximo $maxBackups copias)..."
    $backups = Get-ChildItem -Path $backupDir -Filter "minecraft-backup-*.zip" | Sort-Object CreationTime -Descending
    if ($backups.Count -gt $maxBackups) {
        $backupsToDelete = $backups | Select-Object -Skip $maxBackups
        foreach ($backup in $backupsToDelete) {
            Write-Host "--- Borrando backup antiguo: $($backup.Name)"
            Remove-Item -Path $backup.FullName -Force
        }
    }
    Write-Host "--- Backup y sincronización completados."
}

# --- Comprobación de servicio activo ---
if ((docker logs mc-server | Select-Object -Last 1) -match "Server empty for 60 seconds") {
    Write-Host "Servidor inactivo, deteniendo script."
    exit
}
Write-Host "Servidor activo, continuando..."

# --- Flujo de ejecución ---
Detener-Stack
Hacer-Backup-Y-Subir
Levantar-Stack
