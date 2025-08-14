#!/bin/bash
# Script de inicio para configurar el servidor de Minecraft en Linux

# --- CONFIGURACIÓN ---
COMPRESSED_DATA="data.zip"
INSTALL_DIR="$(dirname "$(realpath "$0")")/../.."
# ---------------------

# --- FUNCIONES ---
check_and_install_unzip() {
    if ! command -v unzip &> /dev/null; then
        echo "--- El programa 'unzip' no esta instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y unzip
        echo "--- 'unzip' instalado."
    else
        echo "--- 'unzip' ya esta instalado."
    fi
}

check_and_install_zip() {
    if ! command -v zip &> /dev/null; then
        echo "--- El programa 'zip' no esta instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y zip
        echo "--- 'zip' instalado."
    else
        echo "--- 'zip' ya esta instalado."
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
        echo "--- Docker instalado. Por favor, cierra la sesion y vuelve a entrar para que los cambios tengan efecto."
    else
        echo "--- Docker ya esta instalado."
    fi

    if ! command -v docker-compose &> /dev/null; then
      echo "--- Docker Compose no encontrado. Intentando instalar..."
      echo "--- Docker Compose (plugin) instalado."
    fi
}

check_and_install_cron() {
    if ! command -v crontab &> /dev/null; then
        echo "--- El programa 'cron' no esta instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y cron
        echo "--- 'cron' instalado."
    else
        echo "--- 'cron' ya esta instalado."
    fi
}

decompress_data() {
    if [ ! -f "$INSTALL_DIR/$COMPRESSED_DATA" ]; then
        echo "--- Archivo de datos comprimido '$COMPRESSED_DATA' no encontrado. Saliendo."
        exit 1
    fi
    mkdir -p "$INSTALL_DIR/data"
    echo "--- Descomprimiendo la carpeta de datos..."
    unzip -o "$INSTALL_DIR/$COMPRESSED_DATA" -d "$INSTALL_DIR/data"
    echo "--- Carpeta 'data' descomprimida con exito."
}

start_and_schedule() {
    echo "--- Configurando y levantando el servidor..."
    cd "$INSTALL_DIR" || exit
    ./scripts/linux/levantar.sh
    ./scripts/linux/schedule_backup.sh
    echo "--- Servidor iniciado y tareas de backup programadas."
}

# --- EJECUCIÓN ---
echo "--- Iniciando el script de instalacion del servidor de Minecraft..."
check_and_install_unzip
check_and_install_zip
check_and_install_docker
check_and_install_cron
decompress_data
start_and_schedule
echo "--- Configuracion completa! El servidor esta funcionando."