#!/bin/bash
# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
GITHUB_REPO="https://github.com/erickturriago/servidor_minecraft.git"
GITHUB_TOKEN="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"
MAX_BACKUPS=15
# ---------------------

BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

cd "$BASE_DIR" || exit

function detener_stack() {
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con exito."
}

function levantar_stack() {
    echo "--- Levantando stack: $STACK_NAME..."
    docker-compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con exito."
}

function hacer_backup_y_subir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/minecraft-backup-$timestamp.zip"

    # --- Backup local ---
    echo "--- Creando backup local de los mundos y plugins en $backup_file..."
    cd "$DATA_DIR"
    zip -r -q "$backup_file" world world_nether world_the_end plugins
    cd "$BASE_DIR"
    echo "--- Backup local completado: $backup_file"

    # --- Preparar para Git ---
    echo "--- Comprimiendo el mundo y los plugins para subir a Git..."
    rm -f "$COMPRESSED_DATA"
    cd "$DATA_DIR"
    zip -r -q "$COMPRESSED_DATA" world world_nether world_the_end plugins
    cd "$BASE_DIR"
    echo "--- Archivo 'data.zip' creado con exito."

    # --- Subir a Git ---
    GIT_URL_WITH_TOKEN="https://oauth2:$GITHUB_TOKEN@github.com/erickturriago/servidor_minecraft.git"
    git rm -r --cached "data" >/dev/null 2>&1

    if [ ! -d ".git" ]; then
        git init
        git remote add origin "$GITHUB_REPO"
    fi

    echo "--- Agregando archivos al control de versiones..."
    echo "data/" > .gitignore
    git add .
    git commit -m "Backup automatico - $(date +"%Y-%m-%d %H:%M:%S")"

    echo "--- Subiendo cambios a GitHub..."
    git push "$GIT_URL_WITH_TOKEN" main

    echo "--- Gestionando backups (maximo $MAX_BACKUPS copias)..."
    while [ $(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup' | wc -l) -gt $MAX_BACKUPS ]; do
        OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | grep 'minecraft-backup' | tail -n 1)
        echo "--- Borrando el backup mas antiguo: $OLDEST_BACKUP"
        rm "$BACKUP_DIR/$OLDEST_BACKUP"
    done

    echo "--- Sincronizacion con GitHub y gestion de backups completada."
}

# --- Flujo de ejecución completo ---
detener_stack
hacer_backup_y_subir
levantar_stack