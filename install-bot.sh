#!/bin/bash

reset_ui() {    
    tput cup 0 0 && printf "\033c"    
    printf "\033[H"
    sleep 0.05
    tput clear    
}

set -e
reset_ui

NC='\e[0m'
WHITE='\033[1;97m'
CYAN='\033[38;5;51m'
CYAN_SOFT='\033[38;5;117m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
DIM='\033[2m'

run_step() {
    local text="$1"
    local spin='|/-\'
    local i=0

    tput civis
    for ((j=0; j<14; j++)); do
        i=$(( (i+1) %4 ))
        printf "\r ${CYAN}%c${NC} ${WHITE}%-50s${DIM}...${NC}" \
        "${spin:$i:1}" "$text"
        sleep 0.12
    done

    printf "\r ${GREEN}✔${NC} ${WHITE}%-50s${NC}\n" "$text"
    tput cnorm
}

# ========================================
# HEADER
# ========================================
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}     TELEGRAM BOT + VPS API INSTALLER${NC}"
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ========================================
# USER INPUT DULU (semua di awal)
# ========================================
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}             BOT CONFIGURATION${NC}"
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -rp " Bot Token                  : " BOT_TOKEN < /dev/tty
read -rp " Owner ID                   : " OWNER_ID < /dev/tty
read -rp " Bot Name                   : " BOT_NAME < /dev/tty
BOT_NAME="${BOT_NAME:-RIPZZ STORE}"

echo ""
echo -e "${CYAN_SOFT}━━ PAYMENT VPN (PAKASIR) ━━${NC}"
read -rp " Pakasir Project/Slug       : " PAKASIR_SLUG < /dev/tty
read -rp " Pakasir API Key            : " PAKASIR_API_KEY < /dev/tty
read -rp " Channel notif VPN          : " VPN_TRX_CHANNEL_ID < /dev/tty

echo ""
echo -e "${CYAN_SOFT}━━ PPOB DIGIFLAZZ ━━${NC}"
read -rp " Digiflazz Username         : " DIGIFLAZZ_USERNAME < /dev/tty
read -rp " Digiflazz API Key          : " DIGIFLAZZ_API_KEY < /dev/tty
read -rp " Channel notif PPOB         : " PPOB_TRX_CHANNEL_ID < /dev/tty

echo ""
echo -e "${CYAN_SOFT}━━ PAYMENT PPOB (AUSTINPAY) ━━${NC}"
read -rp " AustinPay API Key          : " AUSTIN_API_KEY < /dev/tty
read -rp " AustinPay API Secret       : " AUSTIN_API_SECRET < /dev/tty
read -rp " AustinPay Base URL [https://austinstore.id] : " AUSTIN_BASE_URL < /dev/tty
AUSTIN_BASE_URL="${AUSTIN_BASE_URL:-https://austinstore.id}"

echo ""
echo -e "${CYAN_SOFT}━━ CHANNEL WAJIB (OPSIONAL) ━━${NC}"
read -rp " Channel wajib join         : " REQUIRED_CHANNEL_ID < /dev/tty
if [[ -n "$REQUIRED_CHANNEL_ID" ]]; then
    read -rp " Link channel wajib         : " REQUIRED_CHANNEL_URL < /dev/tty
else
    REQUIRED_CHANNEL_URL=""
fi

read -rp " Owner Name (opsional)      : " OWNER_NAME < /dev/tty
read -rp " Default role PPOB [bronze] : " DEFAULT_ROLE < /dev/tty
DEFAULT_ROLE="${DEFAULT_ROLE:-bronze}"

if [[ -z "$BOT_TOKEN" || -z "$OWNER_ID" ]]; then
    echo -e "\n${RED}✖ Bot Token dan Owner ID wajib diisi!${NC}"
    exit 1
fi

if [[ -z "$DIGIFLAZZ_USERNAME" || -z "$DIGIFLAZZ_API_KEY" ]]; then
    echo -e "\n${RED}✖ Digiflazz Username dan API Key wajib diisi untuk PPOB!${NC}"
    exit 1
fi

if [[ -z "$AUSTIN_API_KEY" ]]; then
    echo -e "\n${RED}✖ AustinPay API Key wajib diisi untuk payment PPOB!${NC}"
    exit 1
fi

echo ""
echo -e " ${GREEN}✔${NC} ${WHITE}Konfigurasi diterima. Memulai instalasi...${NC}"
echo ""
sleep 1

# ========================================
# INSTALL BASE
# ========================================
run_step "Updating package repository"
apt update -y &> /dev/null

run_step "Installing required dependencies"
apt install -y unzip wget curl openssl jq &> /dev/null

run_step "Removing previous Node.js installation"
apt purge -y nodejs npm &> /dev/null || true
rm -rf /usr/lib/node_modules ~/.npm /usr/bin/node /usr/bin/npm &> /dev/null || true

run_step "Installing Node.js v20"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &> /dev/null
apt install -y nodejs &> /dev/null

# ========================================
# DOWNLOAD BOT
# ========================================
run_step "Downloading bot package"
wget -q -O bot.zip https://raw.githubusercontent.com/ajijainalganteng-wq/TBOT/main/VPNBOT/bot.zip

if [[ ! -f "bot.zip" ]]; then
    echo -e "${RED}✖ Failed to download bot package${NC}"
    exit 1
fi

run_step "Extracting bot files"
rm -rf /tmp/bot_EXTRACT
mkdir -p /tmp/bot_EXTRACT
unzip -o bot.zip -d /tmp/bot_EXTRACT &> /dev/null

BOT_FOLDER=$(find /tmp/bot_EXTRACT -maxdepth 1 -type d ! -name "*EXTRACT" | head -n 1)
[[ -z "$BOT_FOLDER" ]] && { echo -e "${RED}✖ Bot folder not found${NC}"; exit 1; }

run_step "Deploying bot to system"
rm -rf /root/bot
mv "$BOT_FOLDER" /root/bot
chmod +x /root/bot/shell_script/* 2>/dev/null || true

# ========================================
# DETECT BOT IP
# ========================================
BOT_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

# ========================================
# SAVE CONFIG (pakai node untuk JSON aman)
# ========================================
mkdir -p /root/bot/data

run_step "Saving bot configuration"
node -e "
const fs = require('fs');
const data = {
  token: process.argv[1],
  owner_id: process.argv[2],
  bot_name: process.argv[3],
  owner_name: process.argv[4],
  pakasir_slug: process.argv[5],
  pakasir_api_key: process.argv[6],
  vpn_trx_channel_id: process.argv[7],
  ppob_trx_channel_id: process.argv[8],
  digiflazz_username: process.argv[9],
  digiflazz_api_key: process.argv[10],
  austin_base_url: process.argv[11],
  austin_api_key: process.argv[12],
  austin_api_secret: process.argv[13],
  required_channel_id: process.argv[14],
  required_channel_url: process.argv[15],
  default_role: process.argv[16]
};
fs.writeFileSync('/root/bot/data/.avars.json', JSON.stringify(data, null, 2));
" "$BOT_TOKEN" "$OWNER_ID" "$BOT_NAME" "$OWNER_NAME" "$PAKASIR_SLUG" "$PAKASIR_API_KEY" "$VPN_TRX_CHANNEL_ID" "$PPOB_TRX_CHANNEL_ID" "$DIGIFLAZZ_USERNAME" "$DIGIFLAZZ_API_KEY" "$AUSTIN_BASE_URL" "$AUSTIN_API_KEY" "$AUSTIN_API_SECRET" "$REQUIRED_CHANNEL_ID" "$REQUIRED_CHANNEL_URL" "$DEFAULT_ROLE"

run_step "Saving PPOB configuration"
cat > /root/bot/ppob.env << EOF
BOT_TOKEN=$BOT_TOKEN
TELEGRAM_BOT_TOKEN=$BOT_TOKEN
ADMIN_IDS=$OWNER_ID
BOT_NAME=$BOT_NAME
OWNER_NAME=$OWNER_NAME

PPOB_TRX_CHANNEL_ID=$PPOB_TRX_CHANNEL_ID
TRX_CHANNEL_ID=$PPOB_TRX_CHANNEL_ID
VPN_TRX_CHANNEL_ID=$VPN_TRX_CHANNEL_ID

REQUIRED_CHANNEL_ID=$REQUIRED_CHANNEL_ID
REQUIRED_CHANNEL_URL=$REQUIRED_CHANNEL_URL

DIGIFLAZZ_USERNAME=$DIGIFLAZZ_USERNAME
DIGIFLAZZ_API_KEY=$DIGIFLAZZ_API_KEY

AUSTIN_BASE_URL=$AUSTIN_BASE_URL
AUSTIN_API_KEY=$AUSTIN_API_KEY
AUSTIN_API_SECRET=$AUSTIN_API_SECRET

DEFAULT_ROLE=$DEFAULT_ROLE
MARGIN_BRONZE=12
MARGIN_SILVER=6
MARGIN_GOLD=3
ROLE_PRICE_SILVER=0
ROLE_PRICE_GOLD=0
QRIS_EXPIRE_MINUTES=15
SYNC_INTERVAL_MINUTES=30
PAYMENT_POLL_MS=8000
TRX_POLL_MS=30000
TRX_MAX_POLLS=40
PAGE_SIZE=8
TZ=Asia/Jakarta
STORE_PHOTO=assets/store.jpg
EOF
chmod 600 /root/bot/data/.avars.json /root/bot/ppob.env

run_step "Configuring empty server list"
cat > /root/bot/data/server.js << 'SRVEOF'
const servers = [];

module.exports = servers;
SRVEOF

# ========================================
# INSTALL BOT MODULES + REBUILD SQLITE3
# ========================================
cd /root/bot

run_step "Installing bot modules"
npm install &> /dev/null

run_step "Installing additional modules"
npm install node-telegram-bot-api axios qrcode sql.js ssh2 &> /dev/null

run_step "Removing old sqlite3 (if exists)"
npm uninstall sqlite3 better-sqlite3 &> /dev/null || true

# ========================================
# CREATE BOT SERVICE
# ========================================
run_step "Creating bot service"
cat > /etc/systemd/system/bot.service << EOF
[Unit]
Description=Telegram VPN Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/bot
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

run_step "Starting bot service"
systemctl daemon-reload
systemctl enable bot &> /dev/null
systemctl restart bot

# ========================================
# CLEANUP
# ========================================
run_step "Cleaning temporary files"
cd ~
rm -f bot.zip
rm -rf /tmp/bot_EXTRACT

# ========================================
# VERIFY
# ========================================
sleep 3
BOT_STATUS=$(systemctl is-active bot 2>/dev/null || echo "failed")

# ========================================
# SAVE CREDENTIALS
# ========================================
SAVE_FILE="/root/bot-credentials.txt"
cat > "$SAVE_FILE" << CREDEOF
============================================
  BOT CREDENTIALS
  Tanggal: $(date '+%Y-%m-%d %H:%M:%S')
============================================

BOT TOKEN     : $BOT_TOKEN
OWNER ID      : $OWNER_ID
BOT NAME      : $BOT_NAME
BOT IP        : $BOT_IP

PAKASIR SLUG  : $PAKASIR_SLUG
PAKASIR API   : $PAKASIR_API_KEY
VPN CHANNEL   : $VPN_TRX_CHANNEL_ID

DIGIFLAZZ USER : $DIGIFLAZZ_USERNAME
DIGIFLAZZ API  : $DIGIFLAZZ_API_KEY
PPOB CHANNEL   : $PPOB_TRX_CHANNEL_ID

AUSTIN BASE    : $AUSTIN_BASE_URL
AUSTIN API     : $AUSTIN_API_KEY
AUSTIN SECRET  : $AUSTIN_API_SECRET

============================================
  SIMPAN FILE INI! /root/bot-credentials.txt
============================================
CREDEOF
chmod 600 "$SAVE_FILE"

# ========================================
# RESULT
# ========================================
reset_ui
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✔ Installation completed successfully${NC}"
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ "$BOT_STATUS" == "active" ]]; then
    echo -e " ${WHITE}Bot Service${NC} (${BOT_IP})"
    echo -e "   ${DIM}Status  :${NC} ${GREEN}Running ✔${NC}"
else
    echo -e " ${WHITE}Bot Service${NC} (${BOT_IP})"
    echo -e "   ${DIM}Status  :${NC} ${RED}Error ✖${NC}"
    echo -e "   ${DIM}Debug   :${NC} journalctl -u bot --no-pager -n 20"
fi
echo -e "   ${DIM}Manage  :${NC} systemctl [start|stop|restart|status] bot"
echo -e "   ${DIM}Log     :${NC} journalctl -u bot -f"
echo ""
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " ${YELLOW}⚠  LANGKAH SELANJUTNYA:${NC}"
echo -e ""
echo -e "   ${WHITE}Buka Telegram → /admin → 📌 Add Server${NC}"
echo -e "   ${DIM}Masukkan IP + password root VPS VPN.${NC}"
echo -e "   ${DIM}Bot otomatis install API & sync scripts.${NC}"
echo -e "${CYAN_SOFT}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e " ${DIM}Credentials disimpan di:${NC} ${WHITE}/root/bot-credentials.txt${NC}"
echo ""
