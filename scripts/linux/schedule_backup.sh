#!/bin/bash
# Script para programar un backup automático usando crontab.

# --- CONFIGURACIÓN ---
FREQUENCY_HOURS=2
BACKUP_SCRIPT="backup.sh"
LOG_DIR="/opt/servidor_minecraft/logs"
# ---------------------

# Asegurar carpeta de logs
mkdir -p "$LOG_DIR"

# Obtiene la ruta absoluta del script de backup
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT_PATH="$BASE_DIR/$BACKUP_SCRIPT"

# Cron necesita rutas absolutas y PATH explícito
CRON_JOB="0 */$FREQUENCY_HOURS * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin $BACKUP_SCRIPT_PATH >> $LOG_DIR/backup.log 2>&1"

# Verificar si la tarea ya existe
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT_PATH"; then
    echo "--- La tarea de backup ya existe. Para modificarla, edita crontab manualmente."
    echo "Crontab actual:"
    crontab -l
else
    # Agregar la nueva tarea de crontab
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "--- Tarea de backup programada para ejecutarse cada $FREQUENCY_HOURS horas."
    echo "Nueva entrada en crontab: $CRON_JOB"
fi
