# Script para subir archivos a GitHub y gestionar backups
# Es necesario ejecutar esto en PowerShell

# --- CONFIGURACIÓN ---
$githubRepo = "https://github.com/erickturriago/servidor_minecraft.git"
$githubToken = "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"
$maxBackups = 15
# ---------------------

$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\"
$backupDir = Join-Path -Path $baseDir -ChildPath "backups"
$dataDir = Join-Path -Path $baseDir -ChildPath "data"
$compressedData = Join-Path -Path $baseDir -ChildPath "data.zip"

Set-Location -Path $baseDir

Write-Host "--- Comprimiendo el mundo y los plugins para subir a Git..."
if (Test-Path -Path $compressedData) {
    Remove-Item -Path $compressedData -Force
}
Compress-Archive -Path (Join-Path $dataDir "world"), (Join-Path $dataDir "world_nether"), (Join-Path $dataDir "world_the_end"), (Join-Path $dataDir "plugins") -DestinationPath $compressedData -Force
Write-Host "--- Archivo 'data.zip' creado con exito."

$gitUrlWithToken = "https://oauth2:$githubToken@github.com/erickturriago/servidor_minecraft.git"

if (-not (Test-Path -Path ".git" -PathType Container)) {
    git init
    git remote add origin $githubRepo
}

Set-Content -Path ".gitignore" -Value "data/"

Write-Host "--- Agregando archivos al control de versiones..."
git add .
git commit -m "Backup automatico - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Host "--- Subiendo cambios a GitHub..."
git push $gitUrlWithToken main

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