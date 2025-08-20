#!/bin/bash
# Script para crear un backup y subirlo a Google Drive, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
MAX_BACKUPS=20
REMOTE="gdrive:Servidor_Minecraft"
# ---------------------

BASE_DIR="/opt/servidor_minecraft"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

mkdir -p "$BACKUP_DIR"

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
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
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

    # --- Crear/actualizar data.zip ---
    echo "--- Creando data.zip..."
    rm -f "$COMPRESSED_DATA"
    zip -r -q "$COMPRESSED_DATA" "${items[@]}"
    echo "--- data.zip creado con éxito."

    # --- Subir a Google Drive ---
    echo "--- Subiendo data.zip a Google Drive ($REMOTE)..."
    rclone copy "$COMPRESSED_DATA" "$REMOTE" --progress --drive-chunk-size=64M

    echo "--- Subiendo backup con timestamp a $REMOTE/backups..."
    rclone copy "$backup_file" "$REMOTE/backups" --progress --drive-chunk-size=64M

    # --- Mantener máximo $MAX_BACKUPS en Drive ---
    echo "--- Manteniendo máximo $MAX_BACKUPS backups en Google Drive..."
    local files_to_delete
    files_to_delete=$(rclone ls "$REMOTE/backups" | sort | head -n -$MAX_BACKUPS | awk '{print $2}')

    if [ -n "$files_to_delete" ]; then
        while IFS= read -r oldfile; do
            echo "--- Borrando backup antiguo en Drive: $oldfile"
            rclone delete "$REMOTE/backups/$oldfile"
        done <<< "$files_to_delete"
    fi

    echo "--- Backup y subida completados."
}

# --- Comprobación de servicio activo ---
container_id=$(docker compose -p "$STACK_NAME" ps -q)
if [ -z "$container_id" ]; then
    echo ">>> No se encontró un contenedor en ejecución para $STACK_NAME, abortando."
    exit 1
fi

if ! docker ps -q --no-trunc | grep -q "$container_id"; then
    echo ">>> El contenedor de Minecraft no está corriendo, abortando."
    exit 1
fi

echo "Servidor activo, continuando..."

# --- Flujo de ejecución ---
detener_stack
hacer_backup_y_subir
levantar_stack
