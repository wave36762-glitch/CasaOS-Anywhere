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

source /etc/os-release 2>/dev/null || true

ARCH=$(uname -m)
SYS=$(uname -s)
DISTRO=${ID:-unknown}

# Version: argument ($1), env CASAOS_VERSION, or interactive menu (default: stable)
CASAOS_VERSION="${1:-$CASAOS_VERSION}"
if [ -z "$CASAOS_VERSION" ]; then
    if [ -r /dev/tty ]; then
        echo "Choose the CasaOS version to install:"
        echo "  1) oldest  (0.4.9)"
        echo "  2) stable  (0.4.13) [default]"
        echo "  3) latest  (0.4.15)"
        read -r -p "Your choice [1-3]: " choice < /dev/tty
        case "$choice" in
            1) CASAOS_VERSION=0.4.9 ;;
            3) CASAOS_VERSION=0.4.15 ;;
            *) CASAOS_VERSION=0.4.13 ;;
        esac
    else
        CASAOS_VERSION=0.4.13
    fi
fi
case "$CASAOS_VERSION" in
    oldest) CASAOS_VERSION=0.4.9 ;;
    stable) CASAOS_VERSION=0.4.13 ;;
    latest) CASAOS_VERSION=0.4.15 ;;
esac
if ! [[ "$CASAOS_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}[ ERROR ]${RESET} Invalid version: $CASAOS_VERSION"
    exit 1
fi
echo -e "${GREEN}[  OK  ]${RESET} CasaOS version: $CASAOS_VERSION"

# Profile: argument ($2), env CASAOS_PROFILE, or interactive menu (default: minimal)
CASAOS_PROFILE="${2:-$CASAOS_PROFILE}"
if [ -z "$CASAOS_PROFILE" ]; then
    if [ -r /dev/tty ]; then
        echo "Choose the access level of the container:"
        echo "  1) minimal  (Docker socket only) [default]"
        echo "  2) standard (+ USB devices, host CPU/sys stats)"
        echo "  3) full     (standard + whole host filesystem at /mnt/root)"
        read -r -p "Your choice [1-3]: " pchoice < /dev/tty
        case "$pchoice" in
            2) CASAOS_PROFILE=standard ;;
            3) CASAOS_PROFILE=full ;;
            *) CASAOS_PROFILE=minimal ;;
        esac
    else
        CASAOS_PROFILE=minimal
    fi
fi
case "$CASAOS_PROFILE" in
    minimal|standard|full) ;;
    *) echo -e "${RED}[ ERROR ]${RESET} Invalid profile: $CASAOS_PROFILE (minimal, standard or full)"; exit 1 ;;
esac
echo -e "${GREEN}[  OK  ]${RESET} Profile: $CASAOS_PROFILE"

PROFILE_ARGS=()
if [ "$CASAOS_PROFILE" != "minimal" ]; then
    PROFILE_ARGS+=(-v "/sys:/sys")
    # Only pass USB when the bus exists, otherwise docker run fails (VMs, LXC)
    if [ -e /dev/bus/usb ]; then
        PROFILE_ARGS+=(--device /dev/bus/usb:/dev/bus/usb)
    else
        echo -e "${GREEN}[ INFO  ]${RESET} No /dev/bus/usb on this machine, USB passthrough skipped"
    fi
fi
[ "$CASAOS_PROFILE" = "full" ] && PROFILE_ARGS+=(-v "/:/mnt/root")

echo -e "${GREEN}[  OK  ]${RESET} Your hardware architecture is : $ARCH"
echo -e "${GREEN}[  OK  ]${RESET} Your System is : $SYS"
echo -e "${GREEN}[  OK  ]${RESET} Your Linux Distribution is : $DISTRO"

if ! command -v curl &> /dev/null; then
    if command -v apt-get &> /dev/null; then
        $sudo_cmd apt-get update &> /dev/null && $sudo_cmd apt-get install -y curl &> /dev/null
    elif command -v yum &> /dev/null; then
        $sudo_cmd yum install -y curl &> /dev/null
    elif command -v dnf &> /dev/null; then
        $sudo_cmd dnf install -y curl &> /dev/null
    fi
fi

if command -v docker &> /dev/null; then
    DOCKER_VERSION=$($sudo_cmd docker --version | awk '{print $3}' | tr -d ',')
    echo -e "${GREEN}[  OK  ]${RESET} Current Docker version is $DOCKER_VERSION"
else
    echo -e "${RED}[ ERROR ]${RESET} Docker is not installed"
    echo -e "${GREEN}[ INFO  ]${RESET} Installing docker"
    echo -e "${DIM}"
    curl -fsSL https://get.docker.com | $sudo_cmd sh
    echo -e "${RESET}"
    echo -e "${GREEN}[  OK  ]${RESET} Docker is installed"
fi

echo -e "${GREEN}[  INFO  ]${RESET} Starting docker"
$sudo_cmd systemctl start docker &> /dev/null
$sudo_cmd systemctl enable docker &> /dev/null
echo -e "${GREEN}[  OK  ]${RESET} Docker has started"

echo -e "${GREEN}[  INFO  ]${RESET} Preparing data directory"
$sudo_cmd mkdir -p /DATA
$sudo_cmd chmod 755 /DATA
echo -e "${GREEN}[  OK  ]${RESET} Data directory configured"

if [ "$($sudo_cmd docker ps -a -q -f name=casaos)" ]; then
    echo -e "${GREEN}[  INFO  ]${RESET} Removing existing CasaOS container"
    $sudo_cmd docker rm -f casaos &> /dev/null
    echo -e "${GREEN}[  OK  ]${RESET} Existing container removed"
fi

echo -e "${GREEN}[  INFO  ]${RESET} Pulling and starting CasaOS container"
if $sudo_cmd docker run -d \
    --name casaos \
    --hostname casaos \
    --privileged \
    --cpu-shares 2048 \
    -p 8080:8080 \
    -p 8080:8080/udp \
    -v "/DATA:/DATA" \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    "${PROFILE_ARGS[@]}" \
    --restart unless-stopped \
    dockurr/casa:$CASAOS_VERSION &> /dev/null; then
    echo -e "${GREEN}[  OK  ]${RESET} CasaOS container started successfully"
else
    echo -e "${RED}[ ERROR ]${RESET} Failed to start CasaOS container"
    exit 1
fi

echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"
echo "CasaOS v$CASAOS_VERSION is running at:"
echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"

printed_ips=0
if command -v ip &> /dev/null; then
    while read -r dev cidr; do
        [ -z "$dev" ] && continue
        ip_addr=${cidr%%/*}
        echo -e "${GREEN}-${RESET} http://$ip_addr:8080 ($dev)"
        printed_ips=$((printed_ips + 1))
    done < <(ip -o -4 addr show scope global 2>/dev/null | awk '{print $2, $4}')
fi

if [ "$printed_ips" -eq 0 ]; then
    IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$IP_ADDR" ] && IP_ADDR="127.0.0.1"
    ADAPTER=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)
    [ -z "$ADAPTER" ] && ADAPTER="eth0"
    echo -e "${GREEN}-${RESET} http://$IP_ADDR:8080 ($ADAPTER)"
fi

echo "Open your browser and visit the above address."
echo -e "${GREEN}─────────────────────────────────────────────────────${RESET}"
echo -e "${DIM}"
echo "CasaOS Project  : https://github.com/IceWhaleTech/CasaOS"
echo "CasaOS Team     : https://github.com/IceWhaleTech/CasaOS#maintainers"
echo "CasaOS Discord  : https://discord.gg/knqAbbBbeX"
echo "Website         : https://www.casaos.io"
echo "Online Demo     : http://demo.casaos.io"
echo "Special Thanks  : Sabitech  Cp0204"
echo -e "${RESET}"
