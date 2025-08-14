#!/bin/bash
# Script para programar un backup automatico usando crontab.

# --- CONFIGURACIÓN ---
FREQUENCY_HOURS=6
BACKUP_SCRIPT="./backup.sh"
# ---------------------

BASE_DIR="$(dirname "$0")"
BACKUP_SCRIPT_PATH="$BASE_DIR/$BACKUP_SCRIPT"

CRON_JOB="0 */$FREQUENCY_HOURS * * * $BACKUP_SCRIPT_PATH"

if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT_PATH"; then
    echo "--- La tarea de backup ya existe. Para modificarla, edita crontab manualmente."
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "--- Tarea de backup programada para ejecutarse cada $FREQUENCY_HOURS horas."
fi