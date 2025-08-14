#!/bin/bash
# Script para crear un backup del mundo y los plugins, deteniendo y reiniciando el servidor.

STACK_NAME="minecraft_stack"
BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"

function detener_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con exito."
}

function levantar_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Levantando stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con exito."
}

function hacer_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/minecraft-backup-$timestamp.zip"

    echo "--- Creando backup de los mundos y plugins en $backup_file..."
    cd "$DATA_DIR"
    zip -r -q "$backup_file" world world_nether world_the_end plugins
    echo "--- Backup completado: $backup_file"
}

detener_stack
hacer_backup
levantar_stack