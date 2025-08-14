#!/bin/bash
# Script para levantar el servidor de Minecraft como un stack

STACK_NAME="minecraft_stack"
BASE_DIR="$(dirname "$0")/../../"

function levantar_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Levantando stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con exito."
}

function detener_stack() {
    cd "$BASE_DIR" || exit
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con exito."
}

levantar_stack