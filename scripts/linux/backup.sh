#!/bin/bash
# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
GITHUB_USER="erickturriago"
MAX_BACKUPS=20
# ---------------------

BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

cd "$BASE_DIR" || exit

# --- LECTURA DEL TOKEN ---
if [ -f "$BASE_DIR/token.txt" ]; then
    GITHUB_TOKEN=$(head -n 1 "$BASE_DIR/token.txt")
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "--- ERROR: El archivo token.txt está vacío."
        exit 1
    fi
else
    echo "--- ERROR: Archivo token.txt no encontrado en la raíz del proyecto."
    exit 1
fi

detener_stack() {
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con éxito."
}

levantar_stack() {
    echo "--- Levantando stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con éxito."
}

hacer_backup_y_subir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/minecraft-backup-$timestamp.zip"

    # --- Archivos a respaldar ---
    local items=(
        "$DATA_DIR/world"
        "$DATA_DIR/world_nether"
        "$DATA_DIR/world_the_end"
        "$DATA_DIR/plugins"
        "$DATA_DIR/server.properties"
        "$DATA_DIR/spigot.yml"
        "$DATA_DIR/bukkit.yml"
        "$DATA_DIR/ops.json"
        "$DATA_DIR/whitelist.json"
        "$DATA_DIR/banned-ips.json"
        "$DATA_DIR/banned-players.json"
        "$DATA_DIR/permissions.yml"
    )

    # --- Backup local ---
    echo "--- Creando backup local en $backup_file..."
    zip -r -q "$backup_file" "${items[@]}"
    echo "--- Backup local completado."

    # --- Preparar para Git ---
    echo "--- Creando data.zip para GitHub..."
    rm -f "$COMPRESSED_DATA"
    zip -r -q "$COMPRESSED_DATA" "${items[@]}"
    echo "--- Archivo 'data.zip' creado con éxito."

    # --- Subir a Git ---
    GIT_AUTH_URL="https://$GITHUB_USER:$GITHUB_TOKEN@github.com/erickturriago/servidor_minecraft.git"

    if [ ! -d ".git" ]; then
        git init
        git remote add origin "$GIT_AUTH_URL"
        git branch -M main
    else
        git remote set-url origin "$GIT_AUTH_URL"
    fi

    # --- Configurar .gitignore ---
    touch .gitignore
    grep -qxF "data/" .gitignore || echo "data/" >> .gitignore
    grep -qxF "token.txt" .gitignore || echo "token.txt" >> .gitignore

    # Limpiar cache de data/
    git rm -r --cached "data" >/dev/null 2>&1

    echo "--- Sincronizando con GitHub (git pull)..."
    git pull origin main --allow-unrelated-histories || true

    echo "--- Agregando cambios a Git..."
    git add .
    git commit -m "Backup automático - $(date +"%Y-%m-%d %H:%M:%S")" >/dev/null || true

    echo "--- Subiendo cambios a GitHub..."
    git push -u origin main

    # --- Gestión de backups ---
    echo "--- Manteniendo máximo $MAX_BACKUPS backups..."
    while [ $(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup' | wc -l) -gt $MAX_BACKUPS ]; do
        OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | grep 'minecraft-backup' | tail -n 1)
        echo "--- Borrando backup antiguo: $OLDEST_BACKUP"
        rm "$BACKUP_DIR/$OLDEST_BACKUP"
    done

    echo "--- Backup y sincronización completados."
}

# --- Comprobación de servicio activo ---
if docker logs mc-server | tail -n 1 | grep -q "Server empty for 60 seconds"; then
    echo "Servidor inactivo, deteniendo script."
    exit 0
fi

echo "Servidor activo, continuando..."

# --- Flujo de ejecución ---
detener_stack
hacer_backup_y_subir
levantar_stack
