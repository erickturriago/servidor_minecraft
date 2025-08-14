# Script para programar un backup automatico usando el Programador de Tareas de Windows
# Es necesario ejecutar esto como Administrador en PowerShell

# --- CONFIGURACIÓN ---
$frequencyHours = 6
$backupScript = "backup.ps1"
$taskName = "MinecraftServerBackup"
# ---------------------

$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path
$backupScriptPath = Join-Path -Path $scriptPath -ChildPath $backupScript

try {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "--- La tarea de backup '$taskName' ya existe. Para modificarla, usa el Programador de Tareas."
    } else {
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $frequencyHours) -RepetitionDuration (New-TimeSpan -Days 365)
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$backupScriptPath`""
        
        Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Description "Genera backups automaticos del servidor de Minecraft." | Out-Null
        
        Write-Host "--- Tarea de backup '$taskName' programada para ejecutarse cada $frequencyHours horas."
    }
}
catch {
    Write-Host "--- Error al programar la tarea. Asegurate de ejecutar PowerShell como Administrador."
    Write-Host $_
}