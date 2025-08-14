#!/bin/bash
# Script para restaurar un backup del mundo de Minecraft

STACK_NAME="minecraft_stack"
BASE_DIR="$(dirname "$0")/../../"
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

echo "--- Backups disponibles:"
select BACKUP_FILE in $(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup'); do
    if [ -n "$BACKUP_FILE" ]; then
        echo "Se restaurara el backup $BACKUP_FILE. Quieres continuar? (s/n)"
        read -r confirm
        if [ "$confirm" != "s" ]; then
            echo "--- Restauracion cancelada por el usuario."
            exit
        fi

        echo "--- Deteniendo el servidor para la restauracion..."
        detener_stack

        echo "--- Restaurando desde $BACKUP_FILE..."
        
        echo "--- Borrando la carpeta de datos actual..."
        rm -rf "$DATA_DIR"
        mkdir -p "$DATA_DIR"

        echo "--- Descomprimiendo el backup..."
        unzip "$BACKUP_DIR/$BACKUP_FILE" -d "$DATA_DIR"
        
        echo "--- Iniciando el servidor nuevamente..."
        levantar_stack
        echo "--- Restauracion completada."
        break
    else
        echo "--- Seleccion invalida."
        exit
    fi
done