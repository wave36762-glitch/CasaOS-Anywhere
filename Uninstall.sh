#!/usr/bin/bash

clear
echo -e "\e[0m\c"

GREEN="\e[92m"
RED="\e[31m"
DIM="\e[2m"
WHITE="\e[97m"
RESET="\e[0m"

echo '
     _____                 ____  _____ 
    / ____|               / __ \/ ____|
   | |     __ _ ___  __ _| |  | | (___  
   | |    / _` / __|/ _` | |  | |\___ \ 
   | |___| (_| \__ \ (_| | |__| |____) |
    \_____\__,_|___/\__,_|\____/|_____/ 
                                        
       --- Made by IceWhale with YOU ---
'
export PATH=/usr/sbin:$PATH
export DEBIAN_FRONTEND=noninteractive

set -e

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    sudo_cmd="sudo"
else
    sudo_cmd=""
fi

# Read from /dev/tty when available so piped execution (curl ... | bash) still prompts the user
TTY_INPUT="/dev/stdin"
if [ -r /dev/tty ] && { : < /dev/tty; } 2>/dev/null; then
    TTY_INPUT="/dev/tty"
fi

echo -e "${GREEN}[  INFO  ]${RESET} Starting CasaOS uninstallation wizard..."
echo ""
echo -e "${GREEN}Please answer the following options:${RESET}"

read -r -p "1) Remove appdata (/DATA)? [y/N]: " ans_appdata < "$TTY_INPUT" || ans_appdata=""
read -r -p "2) Remove config (/DATA/AppData/casaos)? [y/N]: " ans_config < "$TTY_INPUT" || ans_config=""
read -r -p "3) Remove docker? [y/N]: " ans_docker < "$TTY_INPUT" || ans_docker=""

echo ""
echo -e "${GREEN}[  INFO  ]${RESET} Processing uninstallation based on your choices..."

if [ "$($sudo_cmd docker ps -a -q -f name=casaos 2>/dev/null)" ]; then
    echo -e "${GREEN}[  INFO  ]${RESET} Stopping CasaOS container"
    $sudo_cmd docker stop casaos &> /dev/null || true
    echo -e "${GREEN}[  OK  ]${RESET} Container stopped"
    
    echo -e "${GREEN}[  INFO  ]${RESET} Removing CasaOS container"
    $sudo_cmd docker rm -f casaos &> /dev/null || true
    echo -e "${GREEN}[  OK  ]${RESET} Container removed"
else
    echo -e "${GREEN}[  OK  ]${RESET} No existing CasaOS container found"
fi

image_removed=false
for tag in 0.4.9 0.4.13 0.4.15 latest; do
    if $sudo_cmd docker image inspect "dockurr/casa:$tag" >/dev/null 2>&1; then
        echo -e "${GREEN}[  INFO  ]${RESET} Removing CasaOS Docker image ($tag)"
        $sudo_cmd docker rmi "dockurr/casa:$tag" >/dev/null 2>&1 || true
        echo -e "${GREEN}[  OK  ]${RESET} Docker image ($tag) removed"
        image_removed=true
    fi
done

if [ "$image_removed" = false ]; then
    echo -e "${GREEN}[  OK  ]${RESET} CasaOS Docker image not present"
fi

# Handle appdata and config cleanly
case "$ans_appdata" in
    [yY][eE][sS]|[yY])
        if [ -d "/DATA" ]; then
            echo -e "${GREEN}[  INFO  ]${RESET} Wiping data directory (/DATA)"
            $sudo_cmd rm -rf /DATA
            echo -e "${GREEN}[  OK  ]${RESET} Data directory wiped"
        else
            echo -e "${GREEN}[  OK  ]${RESET} Data directory does not exist"
        fi
        ;;
    *)
        echo -e "${GREEN}[  OK  ]${RESET} Keeping appdata (/DATA preserved)"
        case "$ans_config" in
            [yY][eE][sS]|[yY])
                echo -e "${GREEN}[  INFO  ]${RESET} Removing configuration files and mounts"
                $sudo_cmd rm -rf /DATA/AppData/casaos &> /dev/null || true
                echo -e "${GREEN}[  OK  ]${RESET} Configurations removed"
                ;;
            *)
                echo -e "${GREEN}[  OK  ]${RESET} Keeping configuration files"
                ;;
        esac
        ;;
esac

case "$ans_docker" in
    [yY][eE][sS]|[yY])
        echo -e "${GREEN}[  INFO  ]${RESET} Uninstalling Docker engine..."
        if command -v apt-get &> /dev/null; then
            $sudo_cmd apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin docker 2>/dev/null || true
            $sudo_cmd apt-get autoremove -y &> /dev/null || true
        elif command -v yum &> /dev/null; then
            $sudo_cmd yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker 2>/dev/null || true
        elif command -v dnf &> /dev/null; then
            $sudo_cmd dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker 2>/dev/null || true
        fi
        echo -e "${GREEN}[  OK  ]${RESET} Docker package removal completed"
        ;;
    *)
        echo -e "${GREEN}[  OK  ]${RESET} Keeping Docker engine installed"
        ;;
esac

echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"
echo "CasaOS uninstallation completed."
echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"
echo -e "${DIM}"
echo "CasaOS Project  : https://github.com/IceWhaleTech/CasaOS"
echo "CasaOS Team     : https://github.com/IceWhaleTech/CasaOS#maintainers"
echo "CasaOS Discord  : https://discord.gg/knqAbbBbeX"
echo "Website         : https://www.casaos.io"
echo "Online Demo     : http://demo.casaos.io"
echo "Special Thanks  : Sabitech  Cp0204"
echo -e "${RESET}"
echo -e "${WHITE}Reinstall       : curl -fsSL https://raw.githubusercontent.com/wave36762-glitch/CasaOS-Anywhere/refs/heads/main/Install.sh | sudo bash${RESET}"
echo ""
