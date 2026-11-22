#!/usr/bin/bash

clear
echo -e "\e[0m\c"

GREEN="\e[92m"
RED="\e[31m"
DIM="\e[2m"
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

((EUID)) && sudo_cmd="sudo"

echo -e "${GREEN}[  INFO  ]${RESET} Starting CasaOS uninstallation wizard..."
echo ""
echo -e "${GREEN}Please answer the following options:${RESET}"

read -p "1) Keep appdata? [y/N]: " ans_appdata
read -p "2) Remove config? [y/N]: " ans_config
read -p "3) Remove docker? [y/N]: " ans_docker

echo ""
echo -e "${GREEN}[  INFO  ]${RESET} Processing uninstallation based on your choices..."

if [ "$($sudo_cmd docker ps -a -q -f name=casaos)" ]; then
    echo -e "${GREEN}[  INFO  ]${RESET} Stopping CasaOS container"
    $sudo_cmd docker stop casaos &> /dev/null || true
    echo -e "${GREEN}[  OK  ]${RESET} Container stopped"
    
    echo -e "${GREEN}[  INFO  ]${RESET} Removing CasaOS container"
    $sudo_cmd docker rm -f casaos &> /dev/null
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

case "$ans_appdata" in
    [yY][eE][sS]|[yY])
        echo -e "${GREEN}[  OK  ]${RESET} Skipping appdata wipe (/DATA kept as requested)"
        ;;
    *)
        if [ -d "/DATA" ]; then
            echo -e "${GREEN}[  INFO  ]${RESET} Wiping data directory (/DATA)"
            $sudo_cmd rm -rf /DATA
            echo -e "${GREEN}[  OK  ]${RESET} Data directory wiped"
        else
            echo -e "${GREEN}[  OK  ]${RESET} Data directory does not exist"
        fi
        ;;
esac

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
echo "CasaOS uninstallation process completed."
echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"
echo -e "${DIM}"
echo "CasaOS Project  : https://github.com"
echo "CasaOS Team     : https://github.com#maintainers"
echo "CasaOS Discord  : https://discord.gg"
echo "Website         : https://casaos.io"
echo -e "${RESET}"
