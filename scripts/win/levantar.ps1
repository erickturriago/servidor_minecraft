# Script para levantar el servidor de Minecraft como un stack
# Es necesario ejecutar esto en PowerShell

$stackName = "minecraft_stack"
$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\..\"

function Levantar-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Levantando stack: $stackName..."
    docker compose -p $stackName up -d
    Write-Host "--- Stack '$stackName' levantado con exito."
}

function Detener-Stack {
    Set-Location -Path $baseDir
    Write-Host "--- Deteniendo stack: $stackName..."
    docker compose -p $stackName down
    Write-Host "--- Stack '$stackName' detenido con exito."
}

Levantar-Stack