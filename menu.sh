#!/bin/bash

# --- VARIÁVEIS ---
PM2_PROCESS_NAME="linkazap-bot"
INSTALL_DIR="$HOME/PlayLinky"

# --- CORES ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'

# --- FUNÇÃO PARA MOSTRAR O MENU ---
show_menu() {
    clear
    echo -e "${C_BLUE}===================================${C_NC}"
    echo -e "${C_BLUE}   Painel de Controle LinkaZAP   ${C_NC}"
    echo -e "${C_BLUE}===================================${C_NC}"
    echo -e "Escolha uma opção:"
    echo -e "   ${C_GREEN}1)${C_NC} Iniciar / Reiniciar Bot"
    echo -e "   ${C_YELLOW}2)${C_NC} Parar Bot"
    echo -e "   ${C_BLUE}3)${C_NC} Ver Logs em Tempo Real"
    echo -e "   ${C_RED}4)${C_NC} Desinstalar COMPLETAMENTE"
    echo -e "   ${C_YELLOW}5)${C_NC} Sair"
    echo -e "${C_BLUE}-----------------------------------${C_NC}"
}

# --- LÓGICA DO MENU ---
while true; do
    show_menu
    read -p "Digite sua opção [1-5]: " choice

    case $choice in
        1)
            echo -e "\n${C_GREEN}Iniciando/Reiniciando o processo '$PM2_PROCESS_NAME'...${C_NC}"
            pm2 restart "$PM2_PROCESS_NAME"
            read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
            ;;
        2)
            echo -e "\n${C_YELLOW}Parando o processo '$PM2_PROCESS_NAME'...${C_NC}"
            pm2 stop "$PM2_PROCESS_NAME"
            read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
            ;;
        3)
            echo -e "\n${C_BLUE}Mostrando logs para '$PM2_PROCESS_NAME'. Pressione CTRL+C para sair.${C_NC}"
            pm2 logs "$PM2_PROCESS_NAME"
            read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
            ;;
        4)
            echo -e "\n${C_RED}ATENÇÃO: Esta ação é irreversível!${C_NC}"
            echo -e "${C_YELLOW}Isso irá parar o bot, remover os serviços de inicialização e apagar a pasta '$INSTALL_DIR' com TODOS os seus dados (históricos, contatos, etc).${C_NC}"
            read -p "Digite 'SIM' em maiúsculas para confirmar: " confirmation
            if [ "$confirmation" == "SIM" ]; then
                echo -e "\nIniciando desinstalação..."
                pm2 stop "$PM2_PROCESS_NAME" || true
                pm2 delete "$PM2_PROCESS_NAME" || true
                pm2 save --force || true
                echo "Removendo o diretório $INSTALL_DIR..."
                rm -rf "$INSTALL_DIR"
                echo -e "\n${C_GREEN}Desinstalação concluída. Saindo...${C_NC}"
                exit 0
            else
                echo -e "\n${C_YELLOW}Confirmação inválida. A desinstalação foi cancelada.${C_NC}"
            fi
            read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
            ;;
        5)
            echo -e "\nSaindo..."
            exit 0
            ;;
        *)
            echo -e "\n${C_RED}Opção inválida. Tente novamente.${C_NC}"
            sleep 2
            ;;
    esac
done