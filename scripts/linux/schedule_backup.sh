#!/bin/bash
# Script para programar un backup automático usando crontab.

# --- CONFIGURACIÓN ---
# Frecuencia del backup en horas. Por ejemplo, 6 para cada 6 horas.
FREQUENCY_HOURS=6
# Nombre del script a ejecutar, relativo a la carpeta 'linux'
BACKUP_SCRIPT="backup.sh"
# ---------------------

# Obtiene la ruta absoluta de la carpeta 'linux' donde se encuentra este script
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SCRIPT_PATH="$BASE_DIR/$BACKUP_SCRIPT"

# Crear la entrada de crontab con la ruta absoluta
CRON_JOB="0 */$FREQUENCY_HOURS * * * $BACKUP_SCRIPT_PATH"

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