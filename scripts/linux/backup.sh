#!/bin/bash
# Script para crear un backup y subirlo a Google Drive, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
MAX_BACKUPS=20
REMOTE="gdrive"
REMOTE_DIR="Servidor_Minecraft"
# ---------------------

BASE_DIR="$(dirname "$(realpath "$0")")/../../"
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

    # --- Crear/actualizar data.zip ---
    echo "--- Creando data.zip..."
    rm -f "$COMPRESSED_DATA"
    zip -r -q "$COMPRESSED_DATA" "${items[@]}"
    echo "--- data.zip creado con éxito."

    # --- Subir a Google Drive ---
    echo "--- Subiendo data.zip a Google Drive ($REMOTE:$REMOTE_DIR)..."
    rclone copy "$COMPRESSED_DATA" "$REMOTE:$REMOTE_DIR" --progress --drive-chunk-size=64M

    echo "--- Subiendo backup con timestamp a $REMOTE_DIR/backups..."
    rclone copy "$backup_file" "$REMOTE:$REMOTE_DIR/backups" --progress --drive-chunk-size=64M

    # --- Mantener máximo $MAX_BACKUPS en Drive ---
    echo "--- Manteniendo máximo $MAX_BACKUPS backups en Google Drive..."
    rclone ls "$REMOTE:$REMOTE_DIR/backups" | sort | head -n -$MAX_BACKUPS | awk '{print $2}' | while read -r oldfile; do
        echo "--- Borrando backup antiguo en Drive: $oldfile"
        rclone delete "$REMOTE:$REMOTE_DIR/backups/$oldfile"
    done

    echo "--- Backup y subida completados."
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
