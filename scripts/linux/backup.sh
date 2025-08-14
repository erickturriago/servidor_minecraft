#!/bin/bash
# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
GITHUB_USER="erickturriago"
GITHUB_TOKEN="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"
GIT_URL_WITH_TOKEN="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/servidor_minecraft.git"
MAX_BACKUPS=15
# ---------------------

BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

cd "$BASE_DIR" || exit

function detener_stack() {
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con éxito."
}

function levantar_stack() {
    echo "--- Levantando stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con éxito."
}

function hacer_backup_y_subir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/minecraft-backup-$timestamp.zip"

    # --- Backup local ---
    echo "--- Creando backup local en $backup_file..."
    cd "$DATA_DIR"
    zip -r -q "$backup_file" world world_nether world_the_end plugins
    cd "$BASE_DIR"
    echo "--- Backup local completado."

    # --- Preparar data.zip ---
    echo "--- Comprimiendo mundos y plugins para subir a Git..."
    rm -f "$COMPRESSED_DATA"
    cd "$DATA_DIR"
    zip -r -q "$COMPRESSED_DATA" world world_nether world_the_end plugins
    cd "$BASE_DIR"
    echo "--- data.zip creado."

    # --- Configuración de Git ---
    git rm -r --cached "data" >/dev/null 2>&1

    if [ ! -d ".git" ]; then
        echo "--- Inicializando repositorio Git..."
        git init
        git branch -M main
        git remote add origin "$GIT_URL_WITH_TOKEN"
    else
        echo "--- Configurando remote de Git con token..."
        git remote remove origin >/dev/null 2>&1
        git remote add origin "$GIT_URL_WITH_TOKEN"
    fi

    # --- Commit y push ---
    echo "data/" > .gitignore
    git add .
    git commit -m "Backup automático - $(date +"%Y-%m-%d %H:%M:%S")" || echo "--- No hay cambios para commitear."

    echo "--- Subiendo cambios a GitHub..."
    git push -u origin main

    # --- Gestión de backups locales ---
    echo "--- Gestionando backups (máximo $MAX_BACKUPS)..."
    while [ $(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup' | wc -l) -gt $MAX_BACKUPS ]; do
        OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | grep 'minecraft-backup' | tail -n 1)
        echo "--- Borrando backup más antiguo: $OLDEST_BACKUP"
        rm "$BACKUP_DIR/$OLDEST_BACKUP"
    done

    echo "--- Backup subido y gestión completada."
}

# --- Ejecución ---
detener_stack
hacer_backup_y_subir
levantar_stack
