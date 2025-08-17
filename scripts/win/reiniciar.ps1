# Script unificado para detener, hacer backup y reiniciar el servidor de Minecraft (Docker + Git)

# --- CONFIGURACIÓN ---
$stackName = "minecraft_stack"
$baseDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScript = Join-Path $baseDir "backup.ps1"
# ---------------------

Write-Host "=== Reiniciando servidor de Minecraft ==="

Write-Host "--- Deteniendo stack: $stackName..."
docker compose -p $stackName down
Write-Host "--- Stack detenido."

Write-Host "--- Ejecutando backup..."
& $backupScript

Write-Host "--- Levantando stack: $stackName..."
docker compose -p $stackName up -d
Write-Host "--- Stack levantado con éxito."

Write-Host "=== Proceso completado ==="
