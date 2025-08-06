#!/bin/bash
set -e

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
GDRIVE_FILE_ID="1jhvQs_UYSY0KDbWe6O0PVe0M_Rbs1JEN"
ZIP_FILENAME="PlayLinky.zip"
ZIP_PASSWORD="playlinky2026"
INSTALL_DIR="$HOME/PlayLinky"
PM2_PROCESS_NAME="linkazap-bot"
EXECUTABLE_NAME=".linkazap"
REQUIRED_NODE_VERSION=20

# --- CORES PARA O TERMINAL ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'

# --- FUNÇÃO DE VERIFICAÇÃO DE PRÉ-REQUISITOS ---
check_and_exit() {
    local command_to_check=$1
    local package_name=$2
    local termux_install_cmd=$3
    local ubuntu_install_cmd=$4

    if ! command -v "$command_to_check" >/dev/null 2>&1; then
        echo -e "${C_RED}ERRO: O pré-requisito '${package_name}' não foi encontrado.${C_NC}"
        echo -e "${C_YELLOW}Por favor, instale-o com o comando apropriado para o seu sistema:${C_NC}"
        echo -e "  - Para Termux:   ${C_GREEN}${termux_install_cmd}${C_NC}"
        echo -e "  - Para Ubuntu/Debian: ${C_GREEN}${ubuntu_install_cmd}${C_NC}"
        echo -e "${C_YELLOW}Depois, execute este script de instalação novamente.${C_NC}"
        exit 1
    fi
}

# --- LÓGICA PRINCIPAL DO SCRIPT ---
echo -e "${C_BLUE}=====================================================${C_NC}"
echo -e "${C_BLUE}    Instalador Automatizado do LinkaZAP by PlayLinky   ${C_NC}"
echo -e "${C_BLUE}=====================================================${C_NC}"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${C_YELLOW}Instalação anterior encontrada. Preparando para uma instalação limpa...${C_NC}"
    if command -v "pm2" >/dev/null 2>&1; then
        pm2 stop "$PM2_PROCESS_NAME" || true
        pm2 delete "$PM2_PROCESS_NAME" || true
        pm2 save --force || true
    fi
    rm -rf "$INSTALL_DIR"
    echo -e "${C_GREEN}Ambiente antigo removido com sucesso.${C_NC}"
fi

echo -e "\n${C_BLUE}[ETAPA 1/3] Verificando pré-requisitos do sistema...${C_NC}"
check_and_exit "node" "Node.js" "pkg install nodejs" "sudo apt install nodejs"
check_and_exit "wget" "wget" "pkg install wget" "sudo apt install wget"
check_and_exit "unzip" "unzip" "pkg install unzip" "sudo apt install unzip"
check_and_exit "pm2" "PM2" "npm install -g pm2" "sudo npm install -g pm2"

NODE_VERSION_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION_MAJOR" -lt "$REQUIRED_NODE_VERSION" ]; then
    echo -e "${C_RED}ERRO: Versão do Node.js (${NODE_VERSION_MAJOR}) é incompatível. Requerida: v${REQUIRED_NODE_VERSION}+.${C_NC}"
    exit 1
fi
echo -e "${C_GREEN}Todos os pré-requisitos foram atendidos.${C_NC}"

echo -e "\n${C_BLUE}[ETAPA 2/3] Baixando a aplicação...${C_NC}"
# Método otimizado para grandes arquivos no Google Drive
FILE_URL="https://drive.google.com/uc?export=download&id=$GDRIVE_FILE_ID"
wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate $FILE_URL -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p' > /tmp/confirm_token
CONFIRM_TOKEN=$(cat /tmp/confirm_token)
wget --load-cookies /tmp/cookies.txt "https://drive.google.com/uc?export=download&confirm=$CONFIRM_TOKEN&id=$GDRIVE_FILE_ID" -O "$HOME/$ZIP_FILENAME"
rm -f /tmp/cookies.txt /tmp/confirm_token

# Verifica se o download foi bem-sucedido
if [ ! -f "$HOME/$ZIP_FILENAME" ]; then
    echo -e "${C_RED}ERRO: Falha no download do arquivo!${C_NC}"
    exit 1
fi

echo -e "${C_GREEN}Download concluído.${C_NC}"

echo -e "\n${C_BLUE}[ETAPA 3/3] Configurando a aplicação...${C_NC}"
# Descompacta o ZIP para o diretório de instalação
unzip -P "$ZIP_PASSWORD" "$HOME/$ZIP_FILENAME" -d "$INSTALL_DIR"
rm "$HOME/$ZIP_FILENAME"

cd "$INSTALL_DIR"

# Move os conteúdos para o diretório principal
if [ -d "PlayLinky" ]; then
    mv PlayLinky/* .
    rmdir PlayLinky
fi

# Renomeia o executável e define permissões
mv linkazap "$EXECUTABLE_NAME"
chmod +x "$EXECUTABLE_NAME"
chmod +x whisper
chmod +x menu.sh
echo -e "${C_GREEN}Aplicação configurada com sucesso.${C_NC}"

echo -e "\n${C_BLUE}Iniciando e configurando o serviço de inicialização automática...${C_NC}"
pm2 start "$INSTALL_DIR/$EXECUTABLE_NAME" --name "$PM2_PROCESS_NAME"
pm2 startup
pm2 save --force

echo -e "\n${C_GREEN}========================================================${C_NC}"
echo -e "${C_GREEN}✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                ${C_NC}"
echo -e "${C_GREEN}========================================================${C_NC}"
echo -e "O bot está agora rodando em segundo plano."
echo -e "Para gerenciar a aplicação, use o script de menu:"
echo -e "${C_YELLOW}cd $INSTALL_DIR && ./menu.sh${C_NC}"