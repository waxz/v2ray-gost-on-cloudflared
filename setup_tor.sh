#!/bin/bash
set -e

#=== 0. Sudo Permission Check ===#
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo)"
  exit 1
fi

TOR_SOCKS_PORT=9060
TOR_CONTROL_PORT=9061
V2RAY_PORT=10000           # your local V2Ray port for Cloudflared
V2RAY_USER="v2rayuser"

#=== 1. Ensure Tor Installed ===#
if ! command -v tor &>/dev/null; then
  echo "🌀 Installing Tor..."
  apt update && apt install -y curl jq
  UBUNTU_RELEASE=$(bash <(cat /etc/os-release; echo 'echo ${VERSION_ID/*, /}'))
  UBUNTU_CODENAME=$(bash <(cat /etc/os-release; echo 'echo ${UBUNTU_CODENAME/*, /}'))
  ARCH=$(dpkg --print-architecture)

if [ -f /etc/apt/sources.list.d/tor.list ] ; then rm /etc/apt/sources.list.d/tor.list ; fi
cat << EOF | tee -a /etc/apt/sources.list.d/tor.list
deb     [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $UBUNTU_CODENAME main
deb-src [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $UBUNTU_CODENAME main
EOF

  wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/deb.torproject.org-keyring.gpg >/dev/null
  apt update
  apt install tor deb.torproject.org-keyring

else
  echo "✅ Tor is already installed"
fi

#=== 2. Country Selection ===#
#=== Countries ===#
CODES=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)
declare -A COUNTRIES=(
  [1]="GB:United Kingdom"
  [2]="DE:Germany"
  [3]="FR:France"
  [4]="NL:Netherlands"
  [5]="SE:Sweden"
  [6]="FI:Finland"
  [7]="CH:Switzerland"
  [8]="IT:Italy"
  [9]="ES:Spain"
  [10]="US:United States"
  [11]="CA:Canada"
  [12]="JP:Japan"
  [13]="AU:Australia"
  [14]="SG:Singapore"
  [15]="KR:South Korea"
  [16]="NO:Norway"
  [17]="DK:Denmark"
  [18]="IE:Ireland"
  [19]="NZ:New Zealand"
  [20]="IL:Israel"
  [0]=":Random"
)

echo "=== Tor Exit Node Selection ==="
for i in "${!CODES[@]}"; do
  code="${COUNTRIES[$i]%%:*}"
  name="${COUNTRIES[$i]#*:}"
  flag=""
  case "$code" in
    GB) flag="🇬🇧" ;; DE) flag="🇩🇪" ;; FR) flag="🇫🇷" ;; NL) flag="🇳🇱" ;;
    SE) flag="🇸🇪" ;; FI) flag="🇫🇮" ;; CH) flag="🇨🇭" ;; IT) flag="🇮🇹" ;;
    ES) flag="🇪🇸" ;; US) flag="🇺🇸" ;; CA) flag="🇨🇦" ;; JP) flag="🇯🇵" ;;
    AU) flag="🇦🇺" ;; SG) flag="🇸🇬" ;; KR) flag="🇰🇷" ;; NO) flag="🇳🇴" ;;
    DK) flag="🇩🇰" ;; IE) flag="🇮🇪" ;; NZ) flag="🇳🇿" ;; IL) flag="🇮🇱" ;;
  esac
  printf " %2d) %s %s (%s)\n" "$i" "$flag" "$name" "$code"
done
read -rp "Select [0-20]: " choice

EXIT_CODE="${COUNTRIES[$choice]%%:*}"
EXIT_NAME="${COUNTRIES[$choice]#*:}"
[ -z "$EXIT_NAME" ] && EXIT_NAME="Random"

echo "[*] Configuring Tor exit node: $EXIT_NAME"





#=== 3. Write Tor Config ===#
cat <<EOF >/etc/tor/torrc
SocksPort 0.0.0.0:9060
ControlPort 0.0.0.0:9061
CookieAuthentication 0
ExcludeNodes {cn},{hk},{mo},{kp},{ir},{sy},{pk},{cu},{vn}
EOF

if [ -n "$EXIT_CODE" ]; then
  echo "ExitNodes {$EXIT_CODE}" >>/etc/tor/torrc
  echo "StrictNodes 1" >>/etc/tor/torrc
fi

# Restart Tor
systemctl restart tor
sleep 3

#=== 4. Check Tor status ===#
if nc -z 127.0.0.1 9060; then
  echo "✅ Tor running on port 9060"
else
  echo "❌ Tor failed to start"
  systemctl status tor --no-pager
  exit 1
fi


#=== 5. Verify ===#
echo ""
echo "──────────────────────────────────"
echo "✅ Tor forwarding setup complete!"
echo " Exit Node: $EXIT_NAME"
echo " Tor SOCKS: 127.0.0.1:$TOR_SOCKS_PORT"
echo "──────────────────────────────────"

#=== 6. Check exit IP ===#
echo "🌍 Checking Tor exit node IP..."
curl -s --socks5 127.0.0.1:$TOR_SOCKS_PORT https://ipinfo.io | jq . || echo "⚠️ Could not check IP"
