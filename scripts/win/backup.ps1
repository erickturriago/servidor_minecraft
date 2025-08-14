# Script para crear un backup del mundo y los plugins, deteniendo y reiniciando el servidor.

$stackName = "minecraft_stack"
$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\"
$backupDir = Join-Path -Path $baseDir -ChildPath "backups"
$dataDir = Join-Path -Path $baseDir -ChildPath "data"

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

function Hacer-Backup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path -Path $backupDir -ChildPath "minecraft-backup-$timestamp.zip"
    
    Write-Host "--- Creando backup de los mundos y plugins en $backupFile..."
    Compress-Archive -Path (Join-Path $dataDir "world"), (Join-Path $dataDir "world_nether"), (Join-Path $dataDir "world_the_end"), (Join-Path $dataDir "plugins") -DestinationPath $backupFile -Force
    Write-Host "--- Backup completado: $backupFile"
}

Detener-Stack
Hacer-Backup
Levantar-Stack