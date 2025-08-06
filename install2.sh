#!/bin/bash
set -e

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
GDRIVE_ZIP_URL="https://drive.google.com/uc?export=download&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2"
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

# --- DETECÇÃO INTELIGENTE DE AMBIENTE ---
echo -e "${C_BLUE}Detectando o ambiente do sistema...${C_NC}"
if [[ "$PREFIX" == *"/com.termux"* ]]; then
    echo -e "${C_GREEN}Ambiente Termux detectado.${C_NC}"
    PKG_INSTALL="pkg install -y"
    NPM_GLOBAL_INSTALL="npm install -g"
else
    echo -e "${C_GREEN}Ambiente Linux padrão (Ubuntu/WSL/Debian) detectado.${C_NC}"
    PKG_INSTALL="sudo apt-get update && sudo apt-get install -y"
    NPM_GLOBAL_INSTALL="sudo npm install -g"
fi

# --- FUNÇÕES AUXILIARES ---
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# --- LÓGICA PRINCIPAL DO SCRIPT ---
echo -e "${C_BLUE}=====================================================${C_NC}"
echo -e "${C_BLUE}    Instalador Automatizado do LinkaZAP by PlayLinky   ${C_NC}"
echo -e "${C_BLUE}=====================================================${C_NC}"

if [ -d "$INSTALL_DIR" ]; then
    echo -e "${C_YELLOW}Instalação anterior encontrada. Preparando para uma instalação limpa...${C_NC}"
    if check_command pm2 && pm2 id "$PM2_PROCESS_NAME" &>/dev/null; then
        pm2 stop "$PM2_PROCESS_NAME" || true
        pm2 delete "$PM2_PROCESS_NAME" || true
        pm2 save --force
    fi
    rm -rf "$INSTALL_DIR"
fi

echo -e "\n${C_BLUE}[ETAPA 1/5] Verificando pré-requisitos...${C_NC}"
if ! check_command node; then
    echo -e "${C_RED}ERRO: Node.js não está instalado.${C_NC}"
    echo -e "${C_YELLOW}Por favor, instale o Node.js (versão ${REQUIRED_NODE_VERSION} ou superior) e execute o script novamente.${C_NC}"
    exit 1
fi

NODE_VERSION_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION_MAJOR" -lt "$REQUIRED_NODE_VERSION" ]; then
    echo -e "${C_RED}ERRO: A versão do seu Node.js é ${NODE_VERSION_MAJOR}, mas a versão mínima requerida é ${REQUIRED_NODE_VERSION}.${C_NC}"
    echo -e "${C_YELLOW}Por favor, atualize o seu Node.js e execute o script novamente.${C_NC}"
    exit 1
fi
echo -e "${C_GREEN}Node.js v${NODE_VERSION_MAJOR} encontrado. Requisito atendido.${C_NC}"

echo -e "\n${C_BLUE}[ETAPA 2/5] Verificando outras dependências do sistema...${C_NC}"
$PKG_INSTALL wget unzip
if ! check_command pm2; then
    echo -e "${C_YELLOW}PM2 não encontrado. Instalando PM2 globalmente...${C_NC}"
    $NPM_GLOBAL_INSTALL pm2
fi
echo -e "${C_GREEN}Dependências verificadas com sucesso.${C_NC}"

echo -e "\n${C_BLUE}[ETAPA 3/5] Baixando a aplicação...${C_NC}"
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2" -O "$HOME/$ZIP_FILENAME" && rm -rf /tmp/cookies.txt

echo -e "\n${C_BLUE}[ETAPA 4/5] Configurando a aplicação...${C_NC}"
unzip -P "$ZIP_PASSWORD" "$HOME/$ZIP_FILENAME" -d "$INSTALL_DIR"
rm "$HOME/$ZIP_FILENAME"
cd "$INSTALL_DIR"
mv linkazap "$EXECUTABLE_NAME"
chmod +x "$EXECUTABLE_NAME"
chmod +x whisper
chmod +x menu.sh

echo -e "\n${C_BLUE}[ETAPA 5/5] Configurando o serviço de inicialização automática...${C_NC}"
pm2 start "$INSTALL_DIR/$EXECUTABLE_NAME" --name "$PM2_PROCESS_NAME"
pm2 startup || true
pm2 save --force

echo -e "\n${C_GREEN}========================================================${C_NC}"
echo -e "${C_GREEN}✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                ${C_NC}"
echo -e "${C_GREEN}========================================================${C_NC}"
echo -e "O bot está agora rodando em segundo plano."
echo -e "Para gerenciar a aplicação, navegue até o diretório:"
echo -e "${C_YELLOW}cd $INSTALL_DIR${C_NC}"
echo -e "E execute o script de menu:"
echo -e "${C_YELLOW}./menu.sh${C_NC}"
