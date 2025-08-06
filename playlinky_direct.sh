#!/bin/bash
set -e

# --- Variáveis ---
DOWNLOAD_URL="http://downloader.playlinky.com/PlayLinky.zip"
ZIP_FILE="PlayLinky.zip"
INSTALL_DIR="$HOME/PlayLinky"
ZIP_PASSWORD="playlinky2026"
PM2_PROCESS_NAME="linkazap-bot"
LOG_FILE="$HOME/playlinky_install.log"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- Iniciar log ---
echo -e "${YELLOW}Iniciando instalação...${NC}" | tee "$LOG_FILE"

# --- Verificar dependências ---
check_deps() {
    echo -e "\n${YELLOW}[1/4] Verificando dependências...${NC}" | tee -a "$LOG_FILE"
    local missing=0
    for cmd in node wget unzip pm2; do
        if ! command -v "$cmd" &>> "$LOG_FILE"; then
            echo -e "${RED}✗ Falta: $cmd${NC}" | tee -a "$LOG_FILE"
            missing=1
        fi
    done
    [ $missing -eq 1 ] && exit 1
    echo -e "${GREEN}✓ Dependências OK${NC}" | tee -a "$LOG_FILE"
}

# --- Baixar arquivo ---
download_file() {
    echo -e "\n${YELLOW}[2/4] Baixando (~170MB)...${NC}" | tee -a "$LOG_FILE"
    if [ -f "$ZIP_FILE" ]; then
        rm -f "$ZIP_FILE" &>> "$LOG_FILE"
    fi
    
    wget --show-progress -q "$DOWNLOAD_URL" -O "$ZIP_FILE" &>> "$LOG_FILE" || {
        echo -e "${RED}✗ Download falhou! Verifique:${NC}" | tee -a "$LOG_FILE"
        echo -e "1. Link acessível? Teste manual:" | tee -a "$LOG_FILE"
        echo -e "   ${YELLOW}wget '$DOWNLOAD_URL'${NC}" | tee -a "$LOG_FILE"
        echo -e "2. Log completo em: $LOG_FILE" | tee -a "$LOG_FILE"
        exit 1
    }

    echo -e "${GREEN}✓ Download completo ($(du -h "$ZIP_FILE" | cut -f1))${NC}" | tee -a "$LOG_FILE"
}

# --- Instalar ---
install_app() {
    echo -e "\n${YELLOW}[3/4] Instalando...${NC}" | tee -a "$LOG_FILE"
    
    # Verificar integridade do ZIP
    if ! unzip -tq "$ZIP_FILE" &>> "$LOG_FILE"; then
        echo -e "${RED}✗ ZIP corrompido!${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi

    mkdir -p "$INSTALL_DIR" &>> "$LOG_FILE"
    unzip -P "$ZIP_PASSWORD" "$ZIP_FILE" -d "$INSTALL_DIR" &>> "$LOG_FILE" || {
        echo -e "${RED}✗ Senha incorreta ou erro ao extrair!${NC}" | tee -a "$LOG_FILE"
        exit 1
    }

    cd "$INSTALL_DIR" || exit 1
    chmod +x .linkazap menu.sh whisper &>> "$LOG_FILE"
    echo -e "${GREEN}✓ Arquivos extraídos em: $INSTALL_DIR${NC}" | tee -a "$LOG_FILE"
}

# --- Configurar PM2 ---
setup_pm2() {
    echo -e "\n${YELLOW}[4/4] Configurando PM2...${NC}" | tee -a "$LOG_FILE"
    
    if ! pm2 start .linkazap --name "$PM2_PROCESS_NAME" &>> "$LOG_FILE"; then
        echo -e "${RED}✗ Falha ao iniciar com PM2!${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    pm2 save &>> "$LOG_FILE"
    pm2 startup | grep -v "sudo" | bash &>> "$LOG_FILE"
    echo -e "${GREEN}✓ PM2 configurado${NC}" | tee -a "$LOG_FILE"
}

# --- Principal ---
{
    echo -e "${GREEN}=== Instalador LinkaZAP ==="
    check_deps
    download_file
    install_app
    setup_pm2
    echo -e "\n${GREEN}✅ Instalação concluída!${NC}"
    echo -e "Gerencie com: ${YELLOW}cd $INSTALL_DIR && ./menu.sh${NC}"
    echo -e "Log completo em: ${YELLOW}$LOG_FILE${NC}"
} | tee -a "$LOG_FILE"
