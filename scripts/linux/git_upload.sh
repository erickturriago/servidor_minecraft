#!/bin/bash
# Script para subir archivos a GitHub y gestionar backups.

# --- CONFIGURACIÓN ---
GITHUB_REPO="https://github.com/erickturriago/servidor_minecraft.git"
GITHUB_TOKEN="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"
MAX_BACKUPS=15
# ---------------------

BASE_DIR="$(dirname "$(realpath "$0")")/../../"
BACKUP_DIR="$BASE_DIR/backups"
DATA_DIR="$BASE_DIR/data"
COMPRESSED_DATA="$BASE_DIR/data.zip"

cd "$BASE_DIR" || exit

GIT_URL_WITH_TOKEN="https://oauth2:$GITHUB_TOKEN@github.com/erickturriago/servidor_minecraft.git"

# Limpia el cache de Git de la carpeta data/ antes de proceder
git rm -r --cached "$DATA_DIR" >/dev/null 2>&1

echo "--- Comprimiendo el mundo y los plugins para subir a Git..."
rm -f "$COMPRESSED_DATA"
cd "$DATA_DIR"
zip -r -q "$COMPRESSED_DATA" world world_nether world_the_end plugins
cd "$BASE_DIR"
echo "--- Archivo 'data.zip' creado con exito."

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