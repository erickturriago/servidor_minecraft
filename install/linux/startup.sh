#!/bin/bash
# Script de inicio para configurar el servidor de Minecraft en Linux

# --- CONFIGURACIÓN ---
COMPRESSED_DATA="data.zip"
INSTALL_DIR="/opt/servidor_minecraft"
REMOTE="gdrive:Servidor_Minecraft"
# ---------------------

# --- FUNCIONES ---

check_and_install_git() {
    if ! command -v git &> /dev/null; then
        echo "--- Git no encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y git
        echo "--- Git instalado."
    else
        echo "--- Git ya está instalado."
    fi
}

check_and_install_rclone() {
    if ! command -v rclone &> /dev/null; then
        echo "--- rclone no encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y rclone
        echo "--- rclone instalado."
    else
        echo "--- rclone ya está instalado."
    fi
}

check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "--- unzip no encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y unzip
        echo "--- unzip instalado."
    else
        echo "--- unzip ya está instalado."
    fi
}

check_and_install_zip() {
    if ! command -v zip &> /dev/null; then
        echo "--- zip no encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y zip
        echo "--- zip instalado."
    else
        echo "--- zip ya está instalado."
    fi
}

check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "--- Docker no encontrado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo usermod -aG docker "$USER"
        echo "--- Docker instalado. Cierra sesión y vuelve a entrar para aplicar permisos."
    else
        echo "--- Docker ya está instalado."
    fi
}

check_and_install_cron() {
    if ! command -v crontab &> /dev/null; then
        echo "--- cron no encontrado. Instalando..."
        sudo apt-get update && sudo apt-get install -y cron
        echo "--- cron instalado."
    else
        echo "--- cron ya está instalado."
    fi
}

download_data() {
    echo "--- Descargando $COMPRESSED_DATA desde Google Drive..."
    mkdir -p "$INSTALL_DIR"
    rclone copy "$REMOTE/$COMPRESSED_DATA" "$INSTALL_DIR" --progress || {
        echo ">>> ERROR: No se pudo descargar $COMPRESSED_DATA desde Google Drive."
        exit 1
    }
    echo "--- Descarga completa."
}

decompress_data() {
    if [ ! -f "$INSTALL_DIR/$COMPRESSED_DATA" ]; then
        echo "--- Archivo $COMPRESSED_DATA no encontrado en $INSTALL_DIR. Abortando."
        exit 1
    fi

    mkdir -p "$INSTALL_DIR/data"
    echo "--- Descomprimiendo el mundo de Minecraft..."
    unzip -o -O UTF-8 "$INSTALL_DIR/$COMPRESSED_DATA" -d "$INSTALL_DIR/data"
    echo "--- Mundo restaurado en '$INSTALL_DIR/data'."
}

start_and_schedule() {
    echo "--- Configurando permisos para el contenedor..."
    sudo chown -R 1000:1000 "$INSTALL_DIR/data"
    sudo chmod -R u+rwx "$INSTALL_DIR/data"
    echo "--- Permisos ajustados con éxito."

    echo "--- Levantando servidor y programando backups..."
    cd "$INSTALL_DIR" || exit 1
    ./scripts/linux/levantar.sh
    ./scripts/linux/schedule_backup.sh
    echo "--- Servidor iniciado y backups programados."

    echo "--- Sincronizando backups existentes con Google Drive..."
    mkdir "$INSTALL_DIR/backups"
    rclone copy "$INSTALL_DIR/backups" "$REMOTE/backups" --progress
    echo "--- Backups sincronizados."
}

# --- EJECUCIÓN ---
echo "--- Iniciando el script de arranque del servidor de Minecraft..."
check_and_install_git
check_and_install_rclone
check_and_install_unzip
check_and_install_zip
check_and_install_docker
check_and_install_cron
download_data
decompress_data
start_and_schedule
echo "--- Todo listo! El servidor está funcionando."
