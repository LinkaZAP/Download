#!/bin/bash
set -e

# --- VARIÁVEIS DE CONFIGURAÇÃO ---
# URL de download direto do Google Drive
GDRIVE_ZIP_URL="https://drive.google.com/uc?export=download&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2"
# Nome do arquivo ZIP para salvar temporariamente
ZIP_FILENAME="PlayLinky.zip"
# Senha para o arquivo ZIP
ZIP_PASSWORD="playlinky2026"
# Nome do diretório de instalação
INSTALL_DIR="$HOME/PlayLinky"
# Nome do processo no PM2
PM2_PROCESS_NAME="linkazap-bot"
# Nome do executável (oculto)
EXECUTABLE_NAME=".linkazap"

# --- CORES PARA O TERMINAL ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

# --- FUNÇÕES AUXILIARES ---
check_command() {
    command -v "$1" >/dev/null 2>&1
}

install_package() {
    local package=$1
    local cmd=$2
    echo -e "${C_YELLOW}Verificando se o '$package' está instalado...${C_NC}"
    if ! check_command "$cmd"; then
        echo -e "${C_YELLOW}'$package' não encontrado. Tentando instalar via apt...${C_NC}"
        sudo apt-get update && sudo apt-get install -y "$package"
        if ! check_command "$cmd"; then
            echo -e "${C_RED}ERRO: Falha ao instalar '$package'. Por favor, instale-o manualmente e execute o script novamente.${C_NC}"
            exit 1
        fi
    fi
    echo -e "${C_GREEN}'$package' está disponível.${C_NC}"
}

# --- LÓGICA PRINCIPAL DO SCRIPT ---
echo -e "${C_BLUE}=====================================================${C_NC}"
echo -e "${C_BLUE}    Instalador Automatizado do LinkaZAP by PlayLinky   ${C_NC}"
echo -e "${C_BLUE}=====================================================${C_NC}"

# 1. Parar e remover instalações antigas para garantir um ambiente limpo
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${C_YELLOW}Instalação anterior encontrada. Preparando para uma instalação limpa...${C_NC}"
    if check_command pm2 && pm2 id "$PM2_PROCESS_NAME" &>/dev/null; then
        echo -e "  -> Parando e removendo processo PM2 antigo..."
        pm2 stop "$PM2_PROCESS_NAME" || true
        pm2 delete "$PM2_PROCESS_NAME" || true
        pm2 save --force
    fi
    echo -e "  -> Removendo diretório de instalação antigo..."
    rm -rf "$INSTALL_DIR"
fi

# 2. Verificar e instalar dependências do sistema
install_package "wget" "wget"
install_package "unzip" "unzip"
install_package "nodejs" "node"

# 3. Verificar PM2
if ! check_command pm2; then
    echo -e "${C_YELLOW}PM2 não encontrado. Instalando PM2 globalmente...${C_NC}"
    sudo npm install -g pm2
    echo -e "${C_GREEN}PM2 instalado com sucesso.${C_NC}"
fi

# 4. Baixar o arquivo da aplicação do Google Drive
echo -e "\n${C_BLUE}[ETAPA 1/4] Baixando a aplicação do Google Drive...${C_NC}"
# O '--no-check-certificate' ajuda a evitar problemas de certificado em alguns sistemas
# O 'wget' precisa de uma "confirmação" para arquivos grandes do GDrive.
wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1Vkew5lI2QvLsPiL5cqmbTExiBVBEqRb2" -O "$HOME/$ZIP_FILENAME" && rm -rf /tmp/cookies.txt

# 5. Extrair a aplicação
echo -e "${C_BLUE}[ETAPA 2/4] Extraindo arquivos para $INSTALL_DIR...${C_NC}"
unzip -P "$ZIP_PASSWORD" "$HOME/$ZIP_FILENAME" -d "$INSTALL_DIR"
rm "$HOME/$ZIP_FILENAME"
cd "$INSTALL_DIR"

# 6. Renomear para ocultar o executável
echo -e "  -> Organizando arquivos internos..."
mv linkazap "$EXECUTABLE_NAME"

# 7. Definir permissões
echo -e "${C_BLUE}[ETAPA 3/4] Configurando permissões necessárias...${C_NC}"
chmod +x "$EXECUTABLE_NAME"
chmod +x whisper
chmod +x menu.sh

# 8. Iniciar com PM2 e configurar para inicialização automática
echo -e "${C_BLUE}[ETAPA 4/4] Configurando o serviço de inicialização automática...${C_NC}"
pm2 start "$INSTALL_DIR/$EXECUTABLE_NAME" --name "$PM2_PROCESS_NAME"
# Tenta executar o comando startup. O PM2 guiará o usuário se for a primeira vez.
pm2 startup || echo -e "${C_YELLOW}Para configurar a inicialização automática, execute o comando que o PM2 sugere acima e pressione Enter.${C_NC}"
pm2 save --force

echo -e "\n${C_GREEN}========================================================${C_NC}"
echo -e "${C_GREEN}✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                ${C_NC}"
echo -e "${C_GREEN}========================================================${C_NC}"
echo -e "O bot está agora rodando em segundo plano."
echo -e "Para gerenciar a aplicação, navegue até o diretório:"
echo -e "${C_YELLOW}cd $INSTALL_DIR${C_NC}"
echo -e "E execute o script de menu:"
echo -e "${C_YELLOW}./menu.sh${C_NC}"