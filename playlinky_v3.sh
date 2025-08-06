#!/bin/bash
set -e

# --- Variáveis ---
DOWNLOAD_URL="http://downloader.playlinky.com/PlayLinky.zip"
ZIP_FILE="$HOME/PlayLinky.zip"
INSTALL_DIR="$HOME/PlayLinky"
ZIP_PASSWORD="playlinky2026"  # Confirme se esta é a senha correta
LOG_FILE="$HOME/playlinky_install.log"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- Função para log ---
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# --- Verificar dependências ---
check_deps() {
    log "\n${YELLOW}[1/4] Verificando dependências...${NC}"
    local missing=0
    for cmd in node wget unzip pm2; do
        if ! command -v "$cmd" &>> "$LOG_FILE"; then
            log "${RED}✗ Falta: $cmd${NC}"
            missing=1
        fi
    done
    [ $missing -eq 1 ] && exit 1
    log "${GREEN}✓ Todas dependências OK${NC}"
}

# --- Baixar arquivo ---
download_file() {
    log "\n${YELLOW}[2/4] Baixando aplicação...${NC}"
    if [ -f "$ZIP_FILE" ]; then
        rm -f "$ZIP_FILE"
    fi
    
    if ! wget --show-progress -q "$DOWNLOAD_URL" -O "$ZIP_FILE" &>> "$LOG_FILE"; then
        log "${RED}✗ Falha no download!${NC}"
        log "Verifique manualmente: wget '$DOWNLOAD_URL' -O teste.zip"
        exit 1
    fi
    
    if [ ! -s "$ZIP_FILE" ]; then
        log "${RED}✗ Arquivo baixado está vazio!${NC}"
        exit 1
    fi
    
    log "${GREEN}✓ Download concluído ($(du -h "$ZIP_FILE" | cut -f1))${NC}"
}

# --- Extrair arquivo ---
extract_file() {
    log "\n${YELLOW}[3/4] Extraindo arquivos...${NC}"
    
    # Verificar se o ZIP é válido
    if ! unzip -tq "$ZIP_FILE" &>> "$LOG_FILE"; then
        log "${RED}✗ Arquivo ZIP corrompido!${NC}"
        exit 1
    fi
    
    # Criar diretório de instalação
    mkdir -p "$INSTALL_DIR"
    
    # Extrair com verificação de senha
    log "Tentando extrair com senha..."
    if ! unzip -P "$ZIP_PASSWORD" "$ZIP_FILE" -d "$INSTALL_DIR" &>> "$LOG_FILE"; then
        log "${RED}✗ Falha na extração! Possíveis causas:${NC}"
        log "1. Senha incorreta (senha testada: '$ZIP_PASSWORD')"
        log "2. Arquivo corrompido"
        log "3. Permissões insuficientes"
        exit 1
    fi
    
    log "${GREEN}✓ Arquivos extraídos em: $INSTALL_DIR${NC}"
}

# --- Configurar aplicação ---
setup_app() {
    log "\n${YELLOW}[4/4] Configurando aplicação...${NC}"
    
    cd "$INSTALL_DIR" || exit 1
    
    # Verificar arquivos essenciais
    for file in .linkazap menu.sh whisper; do
        if [ ! -f "$file" ]; then
            log "${RED}✗ Arquivo faltando: $file${NC}"
            exit 1
        fi
        chmod +x "$file"
    done
    
    # Configurar PM2
    if ! pm2 start .linkazap --name linkazap-bot &>> "$LOG_FILE"; then
        log "${RED}✗ Falha ao iniciar com PM2${NC}"
        exit 1
    fi
    
    pm2 save &>> "$LOG_FILE"
    log "${GREEN}✓ Aplicação configurada com sucesso${NC}"
}

# --- Execução principal ---
{
    echo -e "${GREEN}=== Instalador LinkaZAP v3 ==="
    check_deps
    download_file
    extract_file
    setup_app
    
    echo -e "\n${GREEN}✅ Instalação concluída!${NC}"
    echo -e "Acesse o diretório: ${YELLOW}cd $INSTALL_DIR${NC}"
    echo -e "Execute o menu: ${YELLOW}./menu.sh${NC}"
    echo -e "Log completo: ${YELLOW}cat $LOG_FILE${NC}"
} | tee -a "$LOG_FILE"