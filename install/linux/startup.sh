#!/bin/bash
# Script de inicio para configurar el servidor de Minecraft en Linux

# --- CONFIGURACIÓN ---
COMPRESSED_DATA="data.zip"
INSTALL_DIR="/opt/minecraft-server"
# ---------------------

# --- FUNCIONES ---
check_and_install_zip_tools() {
    # Instalar unzip
    if ! command -v unzip &> /dev/null; then
        echo "--- El programa 'unzip' no está instalado. Instalando..."
        sudo apt-get update
        sudo apt-get install -y unzip
        echo "--- 'unzip' instalado."
    else
        echo "--- 'unzip' ya está instalado."
    fi

    # Instalar zip
    if ! command -v zip &> /dev/null; then
        echo "--- El programa 'zip' no está instalado. Instalando..."
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
        sudo apt-get install -y ca-certificates curl

        # Configurar llave GPG
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Agregar repositorio oficial
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Agregar usuario actual al grupo docker
        sudo usermod -aG docker "$USER"
        echo "--- Docker instalado. Por favor, cierra la sesión y vuelve a entrar para que los cambios tengan efecto."
    else
        echo "--- Docker ya está instalado."
    fi
}

decompress_data() {
    if [ ! -f "$COMPRESSED_DATA" ]; then
        echo "--- Archivo de datos comprimido '$COMPRESSED_DATA' no encontrado. Saliendo."
        exit 1
    fi
    mkdir -p ./data
    echo "--- Descomprimiendo la carpeta de datos..."
    unzip -o "$COMPRESSED_DATA" -d "./data"
    echo "--- Carpeta 'data' descomprimida con éxito."
}

start_and_schedule() {
    echo "--- Configurando y levantando el servidor..."
    ./scripts/linux/levantar.sh
    ./scripts/linux/schedule_backup.sh
    echo "--- Servidor iniciado y tareas de backup programadas."
}

# --- EJECUCIÓN ---
echo "--- Iniciando el script de instalación del servidor de Minecraft..."
check_and_install_zip_tools
check_and_install_docker
decompress_data
start_and_schedule
echo "--- Configuración completa! El servidor está funcionando."
