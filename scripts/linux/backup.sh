#!/bin/bash
# Script para crear un backup y subirlo a Git, deteniendo y reiniciando el servidor.

# --- CONFIGURACIÓN ---
STACK_NAME="minecraft_stack"
GITHUB_USER="erickturriago" # Agrega tu nombre de usuario de GitHub
MAX_BACKUPS=20
# ---------------------

# Usa realpath para obtener una ruta absoluta y fiable al directorio base del proyecto
BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

# Navega al directorio base al inicio del script para asegurar la consistencia
cd "$BASE_DIR" || exit

# --- LECTURA DEL TOKEN ---
# Lee el token del archivo token.txt
if [ -f "$BASE_DIR/token.txt" ]; then
    GITHUB_TOKEN=$(head -n 1 "$BASE_DIR/token.txt")
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "--- ERROR: El archivo token.txt está vacío."
        exit 1
    fi
else
    echo "--- ERROR: Archivo token.txt no encontrado en la raíz del proyecto. Crea uno y añade tu token de GitHub."
    exit 1
fi

function detener_stack() {
    echo "--- Deteniendo stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" down
    echo "--- Stack '$STACK_NAME' detenido con exito."
}

function levantar_stack() {
    echo "--- Levantando stack: $STACK_NAME..."
    docker compose -p "$STACK_NAME" up -d
    echo "--- Stack '$STACK_NAME' levantado con exito."
}

function hacer_backup_y_subir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/minecraft-backup-$timestamp.zip"

    # --- Backup local ---
    echo "--- Creando backup local de los mundos y plugins en $backup_file..."
    # Usa rutas absolutas para el comando zip para evitar errores
    zip -r -q "$backup_file" "$DATA_DIR/world" "$DATA_DIR/world_nether" "$DATA_DIR/world_the_end" "$DATA_DIR/plugins"
    echo "--- Backup local completado: $backup_file"

    # --- Preparar para Git ---
    echo "--- Comprimiendo el mundo y los plugins para subir a Git..."
    rm -f "$COMPRESSED_DATA"
    # Usa rutas absolutas para el comando zip
    zip -r -q "$COMPRESSED_DATA" "$DATA_DIR/world" "$DATA_DIR/world_nether" "$DATA_DIR/world_the_end" "$DATA_DIR/plugins"
    echo "--- Archivo 'data.zip' creado con exito."

    # --- Subir a Git ---
    # Usa el nombre de usuario para la autenticacion, es mas fiable
    # El token se lee del archivo token.txt
    GIT_AUTH_URL="https://$GITHUB_USER:$GITHUB_TOKEN@github.com/erickturriago/servidor_minecraft.git"

    # Limpia el cache de Git de la carpeta data/
    git rm -r --cached "data" >/dev/null 2>&1

    if [ ! -d ".git" ]; then
        git init
        git remote add origin "$GIT_AUTH_URL"
    else
        # Asegura que el remote siempre use la URL de autenticacion
        git remote set-url origin "$GIT_AUTH_URL"
    fi

    echo "--- Agregando archivos al control de versiones..."
    # Asegura que el .gitignore exista y tenga la regla correcta
    echo "data/" > .gitignore
    echo "token.txt" >> .gitignore
    git add .
    git commit -m "Backup automatico - $(date +"%Y-%m-%d %H:%M:%S")"

    echo "--- Subiendo cambios a GitHub..."
    git push origin main

    echo "--- Gestionando backups (maximo $MAX_BACKUPS copias)..."
    while [ $(ls -1 "$BACKUP_DIR" | grep 'minecraft-backup' | wc -l) -gt $MAX_BACKUPS ]; do
        OLDEST_BACKUP=$(ls -1t "$BACKUP_DIR" | grep 'minecraft-backup' | tail -n 1)
        echo "--- Borrando el backup mas antiguo: $OLDEST_BACKUP"
        rm "$BACKUP_DIR/$OLDEST_BACKUP"
    done

    echo "--- Sincronizacion con GitHub y gestion de backups completada."
}

# Comprobación de servicio activo

if docker logs mc-server | tail -n 1 | grep -q "Server empty for 60 seconds"; then
    echo "Servidor inactivo, deteniendo script."
    exit 0
fi

echo "Servidor activo, continuando..."

# --- Flujo de ejecución completo ---

detener_stack
hacer_backup_y_subir
levantar_stack
