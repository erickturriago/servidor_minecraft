#!/bin/bash
# Script de inicio para configurar el servidor de Minecraft en Linux

# --- CONFIGURACIÓN ---
COMPRESSED_DATA="data.zip"
INSTALL_DIR="/opt/servidor_minecraft"
REMOTE="gdrive:Backups_Minecraft/Servidor_Minecraft"
# ---------------------

# --- FUNCIONES ---

check_and_install_git() {
    if ! command -v git &> /dev/null; then
        echo "--- Git no encontrado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y git
        echo "--- Git instalado."
    else
        echo "--- Git ya está instalado."
    fi

    git config --global user.email "turriago-erick@hotmail.com"
    git config --global user.name "Erick Turriago"
    echo "--- Git configurado con autor."
}

check_and_install_rclone() {
    if ! command -v rclone &> /dev/null; then
        echo "--- rclone no encontrado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y rclone
        echo "--- rclone instalado."
    else
        echo "--- rclone ya está instalado."
    fi
}

check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "--- El programa 'unzip' no está instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y unzip
        echo "--- 'unzip' instalado."
    else
        echo "--- 'unzip' ya está instalado."
    fi
}

check_and_install_zip() {
    if ! command -v zip &> /dev/null; then
        echo "--- El programa 'zip' no está instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y zip
        echo "--- 'zip' instalado."
    else
        echo "--- 'zip' ya está instalado."
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
        echo "--- Docker instalado. Por favor, cierra la sesión y vuelve a entrar para que los cambios tengan efecto."
    else
        echo "--- Docker ya está instalado."
    fi

    if ! command -v docker-compose &> /dev/null; then
      echo "--- Docker Compose no encontrado. Intentando instalar..."
      echo "--- Docker Compose (plugin) instalado."
    fi
}

check_and_install_cron() {
    if ! command -v crontab &> /dev/null; then
        echo "--- El programa 'cron' no está instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y cron
        echo "--- 'cron' instalado."
    else
        echo "--- 'cron' ya está instalado."
    fi
}

download_data() {
    echo "--- Descargando $COMPRESSED_DATA desde Google Drive..."
    mkdir -p "$INSTALL_DIR"
    rclone copy "$REMOTE/$COMPRESSED_DATA" "$INSTALL_DIR" --progress
    echo "--- Descarga completa."
}

decompress_data() {
    if [ ! -f "$INSTALL_DIR/$COMPRESSED_DATA" ]; then
        echo "--- Archivo de datos comprimido '$COMPRESSED_DATA' no encontrado. Saliendo."
        exit 1
    fi

    mkdir -p "$INSTALL_DIR/data"

    echo "--- Descomprimiendo el mundo de Minecraft..."
    unzip -o -O UTF-8 "$INSTALL_DIR/$COMPRESSED_DATA" -d "$INSTALL_DIR/data"
    echo "--- Mundo restaurado en '$INSTALL_DIR/data'."
}

start_and_schedule() {
    echo "--- Configurando y levantando el servidor..."
    cd "$INSTALL_DIR" || exit
    ./scripts/linux/levantar.sh
    ./scripts/linux/schedule_backup.sh
    echo "--- Servidor iniciado y tareas de backup programadas."

    echo "--- Subiendo backups existentes a Google Drive..."
    rclone copy "$INSTALL_DIR/backups" "$REMOTE/backups" --progress
    echo "--- Backups sincronizados en Google Drive."
}

# --- EJECUCIÓN ---
echo "--- Iniciando el script de instalación del servidor de Minecraft..."
check_and_install_git
check_and_install_rclone
check_and_install_unzip
check_and_install_zip
check_and_install_docker
check_and_install_cron
download_data
decompress_data
start_and_schedule
echo "--- Configuración completa! El servidor está funcionando."
