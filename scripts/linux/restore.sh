#!/bin/bash
# Script para restaurar un backup del mundo de Minecraft

STACK_NAME="minecraft_stack"
BASE_DIR="$(cd "$(dirname "$0")/../../" && pwd)"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
LOG_DIR="$BASE_DIR/logs"

mkdir -p "$LOG_DIR"

detener_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con éxito."
}

levantar_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Levantando stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con éxito."
}

# Listar backups disponibles
BACKUPS=($(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup' || true))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "--- No se encontraron backups en $BACKUP_DIR"
    exit 1
fi

echo "--- Backups disponibles:"
select BACKUP_FILE in "${BACKUPS[@]}"; do
    if [ -n "$BACKUP_FILE" ]; then
        read -r -p "Se restaurará el backup $BACKUP_FILE. ¿Quieres continuar? (s/n): " confirm
        if [ "$confirm" != "s" ]; then
            echo "--- Restauración cancelada por el usuario."
            exit
        fi

        echo "--- Deteniendo el servidor para la restauración..."
        detener_stack

        echo "--- Borrando la carpeta de datos actual..."
        rm -rf "$DATA_DIR"
        mkdir -p "$DATA_DIR"

        echo "--- Restaurando desde $BACKUP_FILE..."
        unzip -o -q "$BACKUP_DIR/$BACKUP_FILE" -d "$DATA_DIR"

        echo "--- Iniciando el servidor nuevamente..."
        levantar_stack

        echo "--- Restauración completada. 🎉"
        exit 0
    else
        echo "--- Selección inválida."
    fi
done
