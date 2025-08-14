# Script para restaurar un backup del mundo de Minecraft
# Es necesario ejecutar esto en PowerShell

$stackName = "minecraft_stack"
$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\"
$backupDir = Join-Path -Path $baseDir -ChildPath "backups"
$dataDir = Join-Path -Path $baseDir -ChildPath "data"

Write-Host "--- Backups disponibles:"
$backups = Get-ChildItem -Path $backupDir -Filter "minecraft-backup-*.zip" | Sort-Object CreationTime
for ($i = 0; $i -lt $backups.Count; $i++) {
    Write-Host "$($i+1). $($backups[$i].Name)"
}

$choice = Read-Host "Elige el numero del backup a restaurar (1-$($backups.Count)) o presiona 'q' para cancelar"

if ($choice -eq "q") {
    Write-Host "--- Restauracion cancelada por el usuario."
    exit
}

if ($choice -ge 1 -and $choice -le $backups.Count) {
    $selectedBackup = $backups[$choice-1]

    $confirm = Read-Host "Se restaurara el backup $($selectedBackup.Name). Quieres continuar? (s/n)"
    if ($confirm -ne "s") {
        Write-Host "--- Restauracion cancelada por el usuario."
        exit
    }

    Write-Host "--- Deteniendo el servidor para la restauracion..."
    Set-Location -Path $baseDir
    docker compose -p $stackName down

    Write-Host "--- Restaurando desde $($selectedBackup.Name)..."

    Write-Host "--- Borrando la carpeta de datos actual..."
    Remove-Item -Path "$dataDir\*" -Force -Recurse

    Write-Host "--- Descomprimiendo el backup..."
    Expand-Archive -Path $selectedBackup.FullName -DestinationPath $dataDir -Force

    Write-Host "--- Iniciando el servidor nuevamente..."
    docker compose -p $stackName up -d
    Write-Host "--- Restauracion completada."
} else {
    Write-Host "--- Seleccion invalida."
}