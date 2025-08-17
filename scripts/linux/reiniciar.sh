#!/bin/bash
# Script unificado para detener, hacer backup y reiniciar el servidor de Minecraft (Docker + Git)

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BASE_DIR="$SCRIPT_DIR"
BACKUP_SCRIPT="$BASE_DIR/backup.sh"
# ---------------------

cd "$BASE_DIR" || exit

echo "=== Reiniciando servidor de Minecraft ==="

echo "--- Deteniendo stack: $STACK_NAME..."
docker compose -p "$STACK_NAME" down
echo "--- Stack detenido."

echo "--- Ejecutando backup..."
bash "$BACKUP_SCRIPT"

echo "--- Levantando stack: $STACK_NAME..."
docker compose -p "$STACK_NAME" up -d
echo "--- Stack levantado con éxito."

echo "=== Proceso completado ==="
