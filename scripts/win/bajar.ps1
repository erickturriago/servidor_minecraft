$stackName = "minecraft_stack"
Write-Host "--- Deteniendo stack: $stackName..."
docker compose -p $stackName down
Write-Host "--- Stack '$stackName' detenido con exito."