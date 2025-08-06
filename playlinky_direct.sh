#!/bin/bash
set -e

# --- Variáveis ---
DOWNLOAD_URL="http://downloader.playlinky.com/PlayLinky.zip"
ZIP_FILE="PlayLinky.zip"
INSTALL_DIR="$HOME/PlayLinky"
ZIP_PASSWORD="playlinky2026"  # Confirme se é a senha correta!
PM2_PROCESS_NAME="linkazap-bot"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- Verificar pré-requisitos ---
check_deps() {
    for cmd in node wget unzip pm2; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}ERRO: '$cmd' não instalado. Instale primeiro!${NC}"
            exit 1
        fi
    done
}

# --- Baixar via link direto ---
download_file() {
    echo -e "${YELLOW}[1/3] Baixando a aplicação...${NC}"
    if ! wget --show-progress -q "$DOWNLOAD_URL" -O "$ZIP_FILE"; then
        echo -e "${RED}Falha no download! Verifique:${NC}"
        echo -e "1. Link disponível? Teste manualmente:"
        echo -e "   ${YELLOW}wget '$DOWNLOAD_URL'${NC}"
        echo -e "2. Servidor online? Ping:"
        echo -e "   ${YELLOW}ping downloader.playlinky.com${NC}"
        exit 1
    fi

    # Verifica se o arquivo é um ZIP válido
    if ! unzip -tq "$ZIP_FILE" &> /dev/null; then
        echo -e "${RED}Arquivo corrompido! Tamanho atual:$(du -h "$ZIP_FILE")${NC}"
        exit 1
    fi
}

# --- Instalar ---
install_app() {
    echo -e "${YELLOW}[2/3] Instalando...${NC}"
    mkdir -p "$INSTALL_DIR"
    unzip -P "$ZIP_PASSWORD" "$ZIP_FILE" -d "$INSTALL_DIR" || {
        echo -e "${RED}Senha incorreta ou arquivo inválido!${NC}"
        exit 1
    }

    cd "$INSTALL_DIR"
    chmod +x .linkazap menu.sh whisper
}

# --- Configurar PM2 ---
setup_pm2() {
    echo -e "${YELLOW}[3/3] Configurando...${NC}"
    pm2 start .linkazap --name "$PM2_PROCESS_NAME"
    pm2 save
    pm2 startup | grep -v "sudo" | bash
}

# --- Principal ---
echo -e "${GREEN}=== Instalador LinkaZAP ==="
check_deps
download_file
install_app
setup_pm2

echo -e "${GREEN}✅ Concluído!${NC}"
echo -e "Gerencie com: ${YELLOW}cd $INSTALL_DIR && ./menu.sh${NC}"